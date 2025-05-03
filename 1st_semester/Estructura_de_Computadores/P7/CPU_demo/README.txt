Carpeta de ejemplos interactivos para la preparación de la segunda práctica evaluable de Estructura de Computadores. 

Contiene una traza ya elaborada para visualizar en gtkwave:
* cpu_tb.vcd: La traza para visualización en gtkwave ya elaborada para el ejemplo del enunciado
* cpu_tb.gtkw: Fichero de configuración para visualizar los elementos importantes de la traza en el gtkwave 

Se invoca desde línea de comandos como "gtkwave cpu_tb.vcd cpu_tb.gtkw"

Contiene dos ficheros con el contenido inicial de la memoria de programa (progfile.dat) y el banco de registros (regfile.dat).

Contiene también diferentes alternativas del ejecutable para simular el ejemplo codificado en el fichero progfile.dat, ya que el simulador de verilog no es compatible entre versiones:
* cpu_tb.vvp: compatible con linux en las salas del Centro de Cálculo (versión 11)
* cpu_tb_v12.vvp: compilado con la versión 12 de icarus verilog
* cpu_tb_vVDI.vvp: compatible con linux en escritorio virtual del entorno VDI (versión 10.3)

Se invoca desde línea de comandos como "vvp cpu_tb.vvp +n=14", donde n=14 es el número de ciclos que va a simular.