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

// Clase para manejar el mapeo de archivos en memoria de forma segura
class SafeMap {
public:
  // Constructor que recibe una vista de cadena y la almacena
  explicit SafeMap(std::string_view sv) noexcept  : sv_{sv} {}
  // Constructor por defecto comentado, por si se necesita en el futuro
  // explicit SafeMap() noexcept : sv_{""} {}          // Mirar para que es esto

  // Eliminamos el constructor de copia para evitar copias accidentales
  SafeMap(const SafeMap&) = delete;
  SafeMap& operator=(const SafeMap&) = delete;

  // Constructor de movimiento para transferir la propiedad del mapeo
  SafeMap(SafeMap&& other) noexcept : sv_{other.sv_} {
    other.sv_ = "";
  }

  // Operador de asignación por movimiento
  SafeMap& operator=(SafeMap&& other) noexcept {
    if (this != &other && sv_ != other.sv_) {
      sv_ = other.sv_;
      other.sv_ = "";
    }
    return *this;
  }

  // Destructor que desmapea la memoria si está mapeada
  ~SafeMap() noexcept  {
    if(!sv_.empty()) {
      if (munmap(const_cast<char*>(sv_.data()), sv_.size()) < 0) {
        std::cerr << "Error al desmapear la memoria: " << strerror(errno) << "\n";
      }  
    }
  }

  // Método para verificar si el mapeo es válido
  [[nodiscard]] bool is_valid() const noexcept {
    return !sv_.empty();
  }

  // Método para obtener la vista de la cadena mapeada
  [[nodiscard]] std::string_view get() const noexcept  {
    return sv_;
  }

private:
  std::string_view sv_; // Almacena la vista de la cadena mapeada
};

// Clase para manejar descriptores de archivos de forma segura
class SafeFD {
public:
  // Constructor que recibe un descriptor de archivo
  explicit SafeFD(int fd) noexcept  : fd_{fd} {}
  // Constructor por defecto que inicializa el descriptor como inválido
  explicit SafeFD() noexcept : fd_{-1} {}

  // Eliminamos el constructor de copia para evitar copias accidentales
  SafeFD(const SafeFD&) = delete;
  SafeFD& operator=(const SafeFD&) = delete;

  // Constructor de movimiento para transferir la propiedad del descriptor
  SafeFD(SafeFD&& other) noexcept : fd_{other.fd_} {
    other.fd_ = -1;
  }

  // Operador de asignación por movimiento
  SafeFD& operator=(SafeFD&& other) noexcept {
    if (this != &other && fd_ != other.fd_) {
      // Cerrar el descriptor de archivo actual si es válido
      close(fd_);
      // Mover el descriptor de 'other' a este objeto
      fd_ = other.fd_;
      other.fd_ = -1;
    }
    return *this;
  }

  // Destructor que cierra el descriptor si es válido
  ~SafeFD() noexcept  {
    if (fd_ >= 0) {
      close(fd_);
    }
  }

  // Método para verificar si el descriptor es válido
  [[nodiscard]] bool is_valid() const noexcept {
    return fd_ >= 0;
  }

  // Método para obtener el descriptor de archivo
  [[nodiscard]] int get() const noexcept  {
    return fd_;
  }

private:
  int fd_; // Almacena el descriptor de archivo
};

// Función para imprimir la ayuda de uso del programa
void print_help() {
  std::cout << "Uso: docserver [-v | --verbose] [-h | --help] [-p <puerto>] ARCHIVO\n\n"
            << "Opciones:\n"
            << "  -h, --help            Muestra esta ayuda y termina.\n"
            << "  -v, --verbose         Activa el modo detallado.\n"
            << "  -p, --port <puerto>   Especifica el puerto para el servidor (por defecto 8080).\n\n";
};

// Función para leer todo el contenido de un archivo y mapearlo en memoria
std::expected<SafeMap, int> read_all(const std::string& path) {
  int fd = open(path.c_str(), O_RDONLY); // Abrimos el archivo en modo lectura
  if (fd < 0) {
    return std::unexpected(errno); // Retornamos el error si falla
  }

  off_t length = lseek(fd, 0, SEEK_END); // Obtenemos el tamaño del archivo
  if (length == -1) {
    close(fd);
    return std::unexpected(errno);
  }

  // Mapeamos el archivo en memoria
  void *mem = mmap(NULL, static_cast<size_t>(length), PROT_READ, MAP_SHARED, fd, 0);
  
  close(fd); // Cerramos el descriptor de archivo ya que no lo necesitamos más
  if (mem == MAP_FAILED) {
    return std::unexpected(errno); // Retornamos el error si el mapeo falla
  }

  // Retornamos el mapeo seguro
  return SafeMap(std::string_view(static_cast<char*>(mem), static_cast<size_t>(length)));
};

// Función para procesar los argumentos de línea de comandos
std::expected<std::tuple<uint16_t, bool, bool, std::string>, std::string> parse_args(int argc, char* argv[]) {
  uint16_t port = 8080; // Puerto por defecto
  bool verbose = false; // Modo detallado desactivado por defecto
  bool show_help = false; // No mostrar ayuda por defecto
  std::string file_path; // Ruta del archivo a servir

  // Iteramos sobre los argumentos
  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg == "-p" || arg == "--port" && i + 1 < argc) {
      port = static_cast<uint16_t>(std::stoi(argv[++i])); // Asignamos el puerto especificado
    } else if (arg == "-v" || arg == "--verbose") {
      verbose = true; // Activamos el modo detallado
    } else if (arg == "-h" || arg == "--help") {
      show_help = true; // Indicamos que se debe mostrar la ayuda
    } else if (!arg.starts_with("-")) {
      file_path = arg; // Asignamos la ruta del archivo
    } else {
      return std::unexpected("Opción desconocida o falta de argumento para " + arg); // Error por opción desconocida
    }
  }

  // Verificamos que se haya proporcionado una ruta de archivo si no se muestra ayuda
  if (file_path.empty() && !show_help) {
    return std::unexpected("Debe proporcionar el nombre del archivo.");
  }

  // Retornamos las opciones configuradas
  return std::make_tuple(port, verbose, show_help, file_path);
};

// ================================================================================================================================

// Función para obtener una variable de entorno
std::string getenv(const std::string& name) {
  char* value = std::getenv(name.c_str());
  return value ? std::string(value) : std::string();
};

// Función para crear y enlazar un socket en el puerto especificado
std::expected<SafeFD, int> make_socket(uint16_t port) {
  int fd = socket(AF_INET, SOCK_STREAM, 0); // Creamos un socket TCP
  if (fd < 0) return std::unexpected(errno); // Retornamos error si falla

  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = INADDR_ANY; // Aceptamos conexiones desde cualquier dirección
  address.sin_port = htons(port); // Convertimos el puerto a formato de red

  // Enlazamos el socket a la dirección y puerto especificados
  if (bind(fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0) {
    close(fd);
    return std::unexpected(errno); // Retornamos error si el bind falla
  }

  return SafeFD(fd); // Retornamos el socket seguro
};

// Función para poner el socket en modo escucha
int listen_connection(const SafeFD& socket) {
  if (listen(socket.get(), 10) < 0) return errno; // Escuchamos con una cola de 10 conexiones
  return 0; // Retornamos 0 si todo está bien
};

// Función para aceptar una conexión entrante
std::expected<SafeFD, int> accept_connection(const SafeFD& socket, sockaddr_in& client_addr) {
  socklen_t len = sizeof(client_addr);
  int client_fd = accept(socket.get(), reinterpret_cast<sockaddr*>(&client_addr), &len);
  if (client_fd < 0) return std::unexpected(errno); // Retornamos error si falla
  return SafeFD(client_fd); // Retornamos el socket del cliente de forma segura
};

// Función para enviar una respuesta al cliente
int send_response(const SafeFD& socket, std::string_view header, std::string_view body = {}) {
  std::ostringstream response;
  response << header << "\r\n\r\n" << body; // Formateamos la respuesta HTTP
  const std::string& response_str = response.str();
  if (send(socket.get(), response_str.c_str(), response_str.size(), 0) < 0) return errno; // Enviamos la respuesta
  return 0; // Retornamos 0 si todo está bien
};

// ================================================================================================================================

int main(int argc, char* argv[]) {
  // Parsear argumentos
  auto args_result = parse_args(argc, argv);
  if (!args_result) {
    std::cerr << "Error: " << args_result.error() << "\n"; // Mostramos el error de los argumentos
    return 1;
  }

  // Desempaquetamos las opciones
  auto [port, verbose, show_help, file_path] = args_result.value();

  if (show_help) {
    print_help(); // Mostramos la ayuda si se solicitó
    return 0;
  }

  // Creamos y enlazamos el socket
  auto socket_result = make_socket(port);
  if (!socket_result) {
    perror("Error al crear o enlazar el socket");
    return socket_result.error();
  }

  SafeFD server_socket = std::move(socket_result.value());

  // Ponemos el socket en modo escucha
  if (listen_connection(server_socket) != 0) {
    perror("Error al poner el socket en escucha");
    return errno;
  }

  // Mostramos que el servidor está escuchando
  if (verbose) {
    std::cerr << "Servidor escuchando en el puerto " << port << "\n";
  } else {
    std::cout << "Servidor escuchando en el puerto " << port << "\n";
  }

  // Bucle principal para aceptar y manejar conexiones
  while (true) {
    sockaddr_in client_address;
    auto client_result = accept_connection(server_socket, client_address);
    if (!client_result) {
      perror("Error al aceptar la conexión");
      continue; // Continuamos al siguiente ciclo si falla
    }

    SafeFD client_socket = std::move(client_result.value());

    // Mostramos información de la conexión si está en modo detallado
    if (verbose) {
      std::cerr << "Conexión aceptada desde " << inet_ntoa(client_address.sin_addr) 
                << ":" << ntohs(client_address.sin_port) << "\n";
    }

    // Intentamos leer todo el contenido del archivo solicitado
    auto file_result = read_all(file_path);
    if (!file_result) {
      int err = file_result.error();
      // Dependiendo del error, enviamos una respuesta HTTP adecuada
      if (err == EACCES) {
        send_response(client_socket, "HTTP/1.1 403 Forbidden");
      } else if (err == ENOENT) {
        send_response(client_socket, "HTTP/1.1 404 Not Found");
      } else {
        send_response(client_socket, "HTTP/1.1 500 Internal Server Error");
      }
      continue; // Continuamos al siguiente ciclo después de manejar el error
    }

    SafeMap file_map = std::move(file_result.value());
    std::ostringstream header;
    header << "Content-Length: " << file_map.get().size(); // Preparamos el encabezado HTTP

    // Enviamos la respuesta con el contenido del archivo
    send_response(client_socket, header.str(), file_map.get());

    // Muestra información sobre el archivo (modo detalladob )
    if (verbose) {
      std::cerr << "Archivo enviado: " << file_path 
                << ", tamaño: " << file_map.get().size() << " bytes.\n";
    }
  }

  return 0; // Fin del programa
}
