<?php include('conexion.php'); ?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Cartilla de Vacunación</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">

<?php include 'header.php'; ?>


<div class="container py-5">
  <h1 class="mb-4 text-center">Cartilla del Paciente</h1>

  <table class="table table-bordered table-striped">
    <thead class="table-dark">
      <tr>
        <th>ID Persona</th>
        <th>Nombre</th>
        <th>Apellido</th>
        <th>Hospital</th>
        <th>Planta</th>
        <th>Habitación</th>
        <th>Dosis 1</th>
        <th>Dosis 2</th>
        <th>Dosis 3</th>
      </tr>
    </thead>
    <tbody>
      <?php
      $query = "SELECT * FROM llistapacientscartilla()";
      $resultado = pg_query($conexion, $query);

      if ($resultado) {
        while ($fila = pg_fetch_assoc($resultado)) {
          echo "<tr>
            <td>{$fila['idpersona']}</td>
            <td>{$fila['nom']}</td>
            <td>{$fila['cognom']}</td>
            <td>{$fila['nomhospital']}</td>
            <td>{$fila['planta']}</td>
            <td>{$fila['habitacio']}</td>
            <td>{$fila['datadosi1']}</td>
            <td>{$fila['quandosi2']}</td>
            <td>{$fila['quandosi3']}</td>
          </tr>";
        }
      } else {
        echo "<tr><td colspan='9' class='text-danger'> Error al cargar los datos: " . pg_last_error($conexion) . "</td></tr>";
      }
      ?>
    </tbody>
  </table>
</div>

</body>
</html>
