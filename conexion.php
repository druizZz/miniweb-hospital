<?php
$conexion = pg_connect("host=localhost dbname=hospital user=postgres password=usuario");
if (!$conexion) {
	 echo pg_last_error(); // para depurar
    die("Error de conexión.");
}
?>
