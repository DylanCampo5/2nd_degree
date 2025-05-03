#include<sys/socket.h>
#include<unistd.h>		//close
#include<arpa/inet.h> 	//htonl
#include<string>

int main() {
  
  // 1.- CREAR EL SOCKED
  int sock_fd = socket(AF_INET, SOCK_STREAM, 0);			// Tipo de familia de protocolo, de inter	// Tipo de Socket, stream para tcp	// Dentro de la familia, la sub
  if (sock_fd < 0) {
  return errno;
  } 								// No funciona a menos que tenga direccion, tonces:


  // 2.- ENLAZAR EL "BIND"
  
  sockaddr_in local_address{};
  local_address.sin_family = AF_INET;
  local_address.sin_addr.s_addr = htonl(INADDR_ANY);
  local_address.sin_port = htons(8080);		
  
  /*
    sockaddr_un local_address{};
    local_address.sun_family = AF_UNIX;
    std::strcpy(local_address.sun_path, "/tmp/my_socket");
  */
  int result = bind(sock_fd,
                    reinterpret_cast<const sockaddr*>(&local_address),
                    sizeof(local_address)
  );
  if (result < 0) {
    close(sock_fd);
    return errno;
  }


  // 3.- HACER ESCUCHAR NUESTRO SOCKED
  sockaddr_in source_address{};
  socklen_t source_address_length; //awdibjawdbahjwbdiajkd

  result = listen(sock_fd, 5); 
  if (result < 0) {
    close(sock_fd);
    return errno;
  }


  // 4.- ACEPTAR CONEXIONES
  int new_fd = accept(sock_fd, reinterpret_cast<sockaddr*>(&source_address),    
                      &source_address_length);
  if (new_fd < 0) {
    close(sock_fd);
    return errno;
  }


  // 5.- ENVIAR EL MENSAJE
  std::string message_text("Holiwi mirik ");

  int bytes_sent = send(new_fd, message_text.data(), message_text.size(), 0);
  if (bytes_sent < 0) {
    close(new_fd);
    close(sock_fd);
    return errno;
  }

  close(new_fd);
  close(sock_fd);

  return 0; 
  
}