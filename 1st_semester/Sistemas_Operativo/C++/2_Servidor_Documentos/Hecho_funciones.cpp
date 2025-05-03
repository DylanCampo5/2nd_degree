#include <sys/socket.h>
#include <unistd.h>      // close
#include <arpa/inet.h>   // htonl, htons
#include <string>
#include <iostream>
#include <cstring>
#include <cerrno>

// 1. Crear el socket
int create_socket() {
    int sock_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_fd < 0) {
        perror("Error al crear el socket");
        return -1;
    }
    return sock_fd;
}

// 2. Enlazar el socket
bool bind_socket(int sock_fd, uint16_t port) {
    sockaddr_in local_address{};
    local_address.sin_family = AF_INET;
    local_address.sin_addr.s_addr = htonl(INADDR_ANY);
    local_address.sin_port = htons(port);

    if (bind(sock_fd, reinterpret_cast<const sockaddr*>(&local_address), sizeof(local_address)) < 0) {
        perror("Error en bind");
        close(sock_fd);
        return false;
    }
    return true;
}

// 3. Escuchar conexiones
bool listen_socket(int sock_fd, int backlog) {
    if (listen(sock_fd, backlog) < 0) {
        perror("Error en listen");
        close(sock_fd);
        return false;
    }
    return true;
}

// 4. Aceptar conexiones
int accept_connection(int sock_fd, sockaddr_in& source_address) {
    socklen_t source_address_length = sizeof(source_address);
    int new_fd = accept(sock_fd, reinterpret_cast<sockaddr*>(&source_address), &source_address_length);
    if (new_fd < 0) {
        perror("Error en accept");
        close(sock_fd);
        return -1;
    }
    return new_fd;
}

// 5. Enviar mensaje
bool send_message(int client_fd, const std::string& message) {
    int bytes_sent = send(client_fd, message.data(), message.size(), 0);
    if (bytes_sent < 0) {
        perror("Error en send");
        close(client_fd);
        return false;
    }
    return true;
}

// Función principal
int main() {
    const uint16_t PORT = 8080;
    const int BACKLOG = 5;
    const std::string MESSAGE = "Holiwi mirik";

    // Crear el socket
    int sock_fd = create_socket();
    if (sock_fd < 0) return errno;

    // Enlazar el socket
    if (!bind_socket(sock_fd, PORT)) return errno;

    // Escuchar conexiones
    if (!listen_socket(sock_fd, BACKLOG)) return errno;

    // Aceptar conexiones
    sockaddr_in source_address{};
    int client_fd = accept_connection(sock_fd, source_address);
    if (client_fd < 0) return errno;

    // Enviar mensaje
    if (!send_message(client_fd, MESSAGE)) {
        close(sock_fd);
        return errno;
    }

    // Cerrar sockets
    close(client_fd);
    close(sock_fd);

    return 0;
}
