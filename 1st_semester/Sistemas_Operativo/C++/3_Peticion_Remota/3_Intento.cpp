#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <cstring>
#include <cerrno>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <expected>
#include <ctime>

// Clase que maneja el mapeo seguro
class SafeMap {
  public:
    // Constructor que inicializa con una vista de cadena
    explicit SafeMap(std::string_view sv) noexcept : sv_{sv} {}

    // Prohibir copias para evitar problemas con el mapeo
    SafeMap(const SafeMap&) = delete;
    SafeMap& operator=(const SafeMap&) = delete;

    // Permitir movimiento para transferir la propiedad del mapeo
    SafeMap(SafeMap&& other) noexcept : sv_{other.sv_} {
      other.sv_ = "";
    }

    SafeMap& operator=(SafeMap&& other) noexcept {
      if (this != &other && sv_ != other.sv_) {
        sv_ = other.sv_;
        other.sv_ = "";
      }
      return *this;
    }

    // Destructor que desmapea la memoria
    ~SafeMap() noexcept {
      if (!sv_.empty()) {
        if (munmap(const_cast<char*>(sv_.data()), sv_.size()) < 0) {
          std::cerr << "Error al desmapear la memoria: " << strerror(errno) << "\r\n";
        }
      }
    }

    // Verifica si el mapeo es válido
    [[nodiscard]] bool is_valid() const noexcept {
      return !sv_.empty();
    }

    // Devuelve la vista de cadena
    [[nodiscard]] std::string_view get() const noexcept {
      return sv_;
    }

  private:
    std::string_view sv_; // Vista de cadena para los datos mapeados
};

// Clase para manejar descriptores de archivo de manera segura
class SafeFD {
  public:
    // Constructor que inicializa con un descriptor de archivo
    explicit SafeFD(int fd) noexcept : fd_{fd} {}
    explicit SafeFD() noexcept : fd_{-1} {}

    // Prohibir copias para evitar problemas con la gestión de recursos
    SafeFD(const SafeFD&) = delete;
    SafeFD& operator=(const SafeFD&) = delete;

    // Permitir movimiento para transferir la propiedad del descriptor
    SafeFD(SafeFD&& other) noexcept : fd_{other.fd_} {
      other.fd_ = -1;
    }

    SafeFD& operator=(SafeFD&& other) noexcept {
      if (this != &other && fd_ != other.fd_) {
        close(fd_);
        fd_ = other.fd_;
        other.fd_ = -1;
      }
      return *this;
    }

    // Destructor que cierra el descriptor si es válido
    ~SafeFD() noexcept {
      if (fd_ >= 0) {
        close(fd_);
      }
    }

    // Verifica si el descriptor es válido
    [[nodiscard]] bool is_valid() const noexcept {
      return fd_ >= 0;
    }

    // Devuelve el descriptor
    [[nodiscard]] int get() const noexcept {
      return fd_;
    }

  private:
    int fd_; // Descriptor de archivo
};

// Imprime la ayuda del programa
void print_help() {
  std::cout << "Uso: docserver [-v | --verbose] [-h | --help] [-p <puerto>] [-b <ruta_base>]\r\n\r\n"
            << "Opciones:\r\n"
            << "  -h, --help            Muestra esta ayuda y termina.\r\n"
            << "  -v, --verbose         Activa el modo detallado.\r\n"
            << "  -p, --port <puerto>   Especifica el puerto para el servidor (por defecto 8080).\r\n"
            << "  -b, --base <ruta>     Especifica el directorio base para las rutas de archivos.\r\n\r\n";
};

// Lee el contenido de un archivo y lo mapea en memoria
std::expected<SafeMap, int> read_all(const std::string& path) {
  int fd = open(path.c_str(), O_RDONLY); // Abre el archivo solo para lectura
  if (fd < 0) return std::unexpected(errno);

  struct stat st;
  if (fstat(fd, &st) < 0) {
    close(fd);
    return std::unexpected(errno);
  }

  void* mapped = mmap(nullptr, st.st_size, PROT_READ, MAP_SHARED, fd, 0); // Mapea el archivo
  close(fd);
  if (mapped == MAP_FAILED) return std::unexpected(errno);

  return SafeMap(std::string_view(static_cast<char*>(mapped), st.st_size)); // Devuelve el mapeo seguro
};

// Parsea los argumentos de línea de comandos
std::expected<std::tuple<uint16_t, bool, bool, std::string>, std::string> parse_args(int argc, char* argv[]) {
  uint16_t port = 8080;
  bool verbose = false;
  bool show_help = false;
  std::string base_path;

  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if ((arg == "-p" || arg == "--port") && i + 1 < argc) {
      port = static_cast<uint16_t>(std::stoi(argv[++i])); // Obtiene el puerto
    } else if (arg == "-v" || arg == "--verbose") {
      verbose = true; // Activa el modo detallado
    } else if (arg == "-h" || arg == "--help") {
      show_help = true; // Muestra la ayuda
    } else if ((arg == "-b" || arg == "--base") && i + 1 < argc) {
      base_path = argv[++i]; // Obtiene la ruta base
    } else {
      return std::unexpected("Opción desconocida o falta de argumento para " + arg); // Devuelve error
    }
  }

  return std::make_tuple(port, verbose, show_help, base_path); // Da los valores
};

// Crea un socket para el servidor
std::expected<SafeFD, int> make_socket(uint16_t port) {
  int fd = socket(AF_INET, SOCK_STREAM, 0); // Crea el socket
  if (fd < 0) return std::unexpected(errno);

  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = INADDR_ANY;
  address.sin_port = htons(port);

  if (bind(fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0) {
    close(fd);
    return std::unexpected(errno);
  }

  return SafeFD(fd); // Devuelve el socket seguro
};

// Pone el socket en modo de escucha
int listen_connection(const SafeFD& socket) {
  if (listen(socket.get(), 10) < 0) return errno;
  return 0;
};

// Acepta una conexión entrante
std::expected<SafeFD, int> accept_connection(const SafeFD& socket, sockaddr_in& client_addr) {
  socklen_t len = sizeof(client_addr);
  int client_fd = accept(socket.get(), reinterpret_cast<sockaddr*>(&client_addr), &len);
  if (client_fd < 0) return std::unexpected(errno);
  return SafeFD(client_fd);
};

// Envía una respuesta HTTP al cliente
int send_response(const SafeFD& socket, std::string_view header, std::string_view body = {}) {
  auto tiempo = std::time(nullptr);
  std::string fecha = std::string("Date: ") + std::asctime(std::localtime(&tiempo));

  std::string message(fecha);
  ssize_t bytes_sent = send(socket.get(), message.data(), message.size(), 0);

  std::ostringstream response;
  response << header << "\r\n\r\n" << body;
  const std::string& response_str = response.str();

  if (send(socket.get(), response_str.c_str(), response_str.size(), 0) < 0)
    return errno;
  return 0;
};

// Recibe una solicitud HTTP del cliente
std::expected<std::string, int> receive_request(const SafeFD& socket, size_t max_size) {
  std::vector<char> buffer(max_size, 0);
  ssize_t bytes_received = recv(socket.get(), buffer.data(), max_size - 1, 0);
  if (bytes_received < 0) {
    return std::unexpected(errno);
  }
  return std::string(buffer.data());
};

// Parsea una solicitud HTTP y obtiene la ruta del archivo solicitado
std::expected<std::string, std::string> parse_request(const std::string& request, const std::string& base_path) {
  std::istringstream stream(request);
  std::string method, path;
  stream >> method >> path;

  if (method != "GET" || path.empty() || path[0] != '/') {
    return std::unexpected("Petición no válida: Método no es GET o ruta no comienza con '/'");
  }

  // Construir ruta completa al archivo
  std::string file_path = base_path + path.substr(1);

  // Verificar si el archivo existe
  struct stat st;
  if (stat(file_path.c_str(), &st) != 0 || !(st.st_mode & S_IFREG)) {
    return std::unexpected("Archivo no encontrado o no válido: " + file_path);
  }

  return file_path;
};

// Función principal del programa
int main(int argc, char* argv[]) {
  auto args_result = parse_args(argc, argv);
  if (!args_result) {
    std::cerr << "Error: " << args_result.error() << "\r\n";
    return 1;
  }

  auto [port, verbose, show_help, base_path] = args_result.value();

  if (show_help) {
    print_help();
    return 0;
  }

  auto socket_result = make_socket(port);
  if (!socket_result) {
    perror("Error al crear o enlazar el socket");
    return socket_result.error();
  }

  SafeFD server_socket = std::move(socket_result.value());
  if (listen_connection(server_socket) != 0) {
    perror("Error al poner el socket en escucha");
    return errno;
  }

  if (verbose) {
    std::cerr << "Servidor escuchando  " << port << "\r\n";
  } else {
    std::cout << "Servidor escuchando  " << port << "\r\n";
  }

  while (true) {
    sockaddr_in client_address;
    auto client_result = accept_connection(server_socket, client_address);
    if (!client_result) {
      perror("Error al aceptar la conexión");
      break;
    }

    SafeFD client_socket = std::move(client_result.value());
    if (verbose) {
      std::cerr << "Conexión aceptada desde " << inet_ntoa(client_address.sin_addr) << ":" << ntohs(client_address.sin_port) << "\r\n";
    }
    auto request_result = receive_request(client_socket, 1024);
    if (!request_result) {
      send_response(client_socket, "HTTP/1.1 400 Bad Request");
      continue;
    }

    auto file_path_result = parse_request(request_result.value(), base_path);
    if (!file_path_result) {
      if (verbose) {
        std::cerr << "Error: " << file_path_result.error() << "\r\n";
      }
      send_response(client_socket, "HTTP/1.1 404 Not Found");
      continue;
    }

    auto file_result = read_all(file_path_result.value());
    if (!file_result) {
      int err = file_result.error();
      if (err == EACCES) {
        send_response(client_socket, "HTTP/1.1 403 Forbidden");
      } else if (err == ENOENT) {
        send_response(client_socket, "HTTP/1.1 404 Not Found");
      } else {
        send_response(client_socket, "HTTP/1.1 500 Internal Server Error");
      }
      continue;
    }

    SafeMap file_map = std::move(file_result.value());
    std::ostringstream header;
    header << "Content-Length: " << file_map.get().size();

    send_response(client_socket, header.str(), file_map.get());
    if (verbose) {
      std::cerr << "Archivo enviado: " << file_path_result.value() << ", tamaño: " << file_map.get().size() << " bytes.\r\n\r\n";
    }
  }

  return 0;
}
