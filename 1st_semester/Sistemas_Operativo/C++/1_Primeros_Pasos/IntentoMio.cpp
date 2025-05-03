#include <iostream>
#include <sstream>
#include <string>
#include <stdexcept>
#include <system_error>
#include <expected> // Para std::expected en C++23
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <vector>
#include <string.h>



class SafeMap {
  public:
    explicit SafeMap(std::string_view sv) noexcept  : sv_{sv} {}
    //explicit SafeMap() noexcept : sv_{""} {}          // Mirar para que es esto

    // Para las copias
    SafeMap(const SafeMap&) = delete;
    SafeMap& operator=(const SafeMap&) = delete;

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

    //MIRAR
    ~SafeMap() noexcept  {
      if(!sv_.empty()) {
        if (munmap(const_cast<char*>(sv_.data()), sv_.size()) < 0) {
          std::cerr << "Error al desmapear la memoria: " << strerror(errno) << "\n";
        }  
      }
    }

    [[nodiscard]] bool is_valid() const noexcept {
      return !sv_.empty();
    }

    [[nodiscard]] std::string_view get() const noexcept  {
      return sv_;
    }

  private:
    std::string_view sv_;

};
/* Para llamar a send_response() pasando el contenido del archivo, ahora se debe
usar el método get() del objeto SafeMap devuelto por read_all(), para obtener el
std::string_view que apunta a la región mapeada.
Con todo eso hecho, ya no es necesario llamar a munmap() explícitamente. Cuando la variable
que contiene el SafeMap salga del ámbito, el destructor de SafeMap se encarga de llamar a
munmap() automáticamente. */

class SafeFD {
  public:
    explicit SafeFD(int fd) noexcept  : fd_{fd} {}
    explicit SafeFD() noexcept : fd_{-1} {}

    SafeFD(const SafeFD&) = delete;
    SafeFD& operator=(const SafeFD&) = delete;

    SafeFD(SafeFD&& other) noexcept : fd_{other.fd_} {
      other.fd_ = -1;
    }

    SafeFD& operator=(SafeFD&& other) noexcept {
      if (this != &other && fd_ != other.fd_) {

      // Cerrar el descriptor de archivo actual
      close(fd_);

      // Mover el descriptor de archivo de 'other' a este objeto
      fd_ = other.fd_;
      other.fd_ = -1;
      }
      return *this;
    }

    ~SafeFD() noexcept  {
      if (fd_ >= 0) {
        close(fd_);
      }
    }

    [[nodiscard]] bool is_valid() const noexcept {
      return fd_ >= 0;
    }

    [[nodiscard]] int get() const noexcept  {
      return fd_;
    }

  private:
    int fd_;
};

std::string build_help_message() {
  std::ostringstream help;
  help << "Uso: docserver [-v | --verbose] [-h | --help] ARCHIVO\n\n"
        << "Opciones:\n"
        << "  -h, --help      Muestra esta ayuda y termina.\n"
        << "  -v, --verbose   Activa el modo detallado.\n\n"
        << "Ejemplo:\n"
        << "  docserver archivo.txt\n";
  return help.str();
};

enum class parse_args_errors {                      // 1
  missing_argument, 
  unknown_option,
};
struct program_options {                             // 2
  bool show_help = false;
  bool output_filename = false;
  std::string additional_args;           // 3
};

std::expected<program_options, parse_args_errors> parse_args(int argc, char* argv[]) {    // 4
  
  std::vector<std::string_view> args(argv + 1, argv + argc);
  program_options options;
  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg == "-h" || arg == "--help") {
      options.show_help = true;
    } 
    else if (arg == "-v" || arg == "--verbose") {
      options.output_filename = true;
    } 
    else if (!arg.starts_with("-")) {
      options.additional_args = arg;
    } 
    else {
      return std::unexpected(parse_args_errors::unknown_option);
    }
  }

  if (options.additional_args.empty() && !options.show_help) {
    return std::unexpected(parse_args_errors::missing_argument);
  }

  return options;                                                      // 7
};
/* 1 Enumeración con los posibles errores al procesar los argumentos de la línea de comandos.
2 Estructura con las opciones admitidas por el programa.
3 Si el programa admite argumentos adicionales que no son opciones, se pueden guardar
en un vector.
4 La función parse_args() devuelve un std::expected que puede contener una estructura program_options en caso de éxito o un parse_args_errors con el motivo del
error en caso de fallo.
5 En caso de que se indique la opción -o o --output pero no se indique el nombre del
archivo de salida, se devuelve parse_args_errors::missing_argument para notificar
el error a la función que ha invocado a parse_args(). Este valor se marca como
std::unexpected para indicar que se ha producido un error.
6 Si se encuentra una opción desconocida, se devuelve el código de error
parse_args_errors::unknown_option. Este valor se marca como std::unexpected
para indicar que se ha producido un error.
7 En caso de éxito, se devuelve la estructura program_options con las opciones encontradas y sus argumentos */

std::expected<SafeMap, int> read_all(const std::string& path) {

  int fd = open(path.c_str(), O_RDONLY);   
  if (fd < 0) {
    return std::unexpected(errno);
  }

  off_t length = lseek(fd, 0, SEEK_END);
  if (length == -1) {
    close(fd);
    return std::unexpected(errno);
  }

  void *mem = mmap(NULL, static_cast<size_t>(length), PROT_READ, MAP_SHARED, fd, 0);          // static_cast<size_t> 
  
  close(fd);
  if (mem == MAP_FAILED) {
    return std::unexpected(errno);
  }

  return SafeMap(std::string_view(static_cast<char*>(mem), static_cast<size_t>(length)));
};

void send_response(std::string_view header, std::string_view body = {}) {     // header == "Content Length: 10"?
  std::cout << header << "\n\n";
  if (!body.empty()) {
    std::cout << body;
  }
};
/* std::ostringstream oss;
oss << "Content-Length: " << size << '\n';
std::string header = oss.str();
std::string header = std::format("Content-Length: {}\n", size);
El body debe tener el contenido del archivo, pero como? */


// ----------------------------------------------------------------------------------


int main(int argc, char* argv[]) {
  auto args_result = parse_args(argc, argv);
    if (!args_result) {
        if (args_result.error() == parse_args_errors::missing_argument) {
            std::cerr << "Error: No se especificó un archivo.\n";
        } else if (args_result.error() == parse_args_errors::unknown_option) {
            std::cerr << "Error: Opción desconocida.\n";
        }
        std::cout << build_help_message();
        return 1;
    }

    program_options options = std::move(args_result.value());

    if (options.show_help) {
        std::cout << build_help_message();
        return 0;
    }

    auto result = read_all(options.additional_args);
    if (!result) {
        int err = result.error();
        if (err == EACCES) {
            send_response("403 Forbidden");
        } else if (err == ENOENT) {
            send_response("404 Not Found");
        } else {
            std::cerr << "Error al leer el archivo: " << strerror(err) << "\n";
        }
        return 1;
    }

    SafeMap file_map = std::move(result.value());
    std::ostringstream header;
    header << "Content-Length: " << file_map.get().size();
    send_response(header.str(), file_map.get());

    if (options.output_filename) {
        std::cerr << "Archivo abierto con éxito: " << options.additional_args << "\n";
        std::cerr << "Tamaño del archivo: " << file_map.get().size() << " bytes.\n";
    }

    return 0;
}
