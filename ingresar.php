<?php include 'conexion.php'; ?>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Ingresar Nuevo Paciente</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">

<?php include 'header.php'; ?>

<div class="container py-5">
  <h2 class="mb-4 text-center">Ingresar Nuevo Paciente</h2>

  <?php
  if (isset($_POST['enviar'])) {
    $idpersona = $_POST['idpersona'];
    $idhospital = $_POST['idhospital'];
    $planta = (int)$_POST['planta'];
    $habitacio = (int)$_POST['habitacio'];
    $estat = strtolower(trim($_POST['estat']));
    $idvirus = $_POST['idvirus'];

    
    $verificar = pg_query($conexion, "SELECT 1 FROM pacient WHERE idpersona = '$idpersona'");
    if (pg_num_rows($verificar) > 0) {
      echo "<div class='alert alert-warning'>Este paciente ya está ingresado en el sistema.</div>";
    } else {
      
      pg_query($conexion, "SET client_min_messages TO NOTICE;");

      
      $query = "SELECT ingresapacient('$idpersona', '$idhospital', $planta, $habitacio, '$estat', '$idvirus')";
      $resultado = pg_query($conexion, $query);

      if ($resultado) {
        echo "<div class='alert alert-success'>Paciente ingresado correctamente.</div>";
      } else {
        echo "<div class='alert alert-danger'>Error al ingresar: " . pg_last_error($conexion) . "</div>";
      }
    }
  }

  
  $hospitales = pg_query($conexion, "SELECT idhospital FROM hospital ORDER BY idhospital");
  $virus = pg_query($conexion, "SELECT idvirus FROM virus ORDER BY idvirus");
  ?>

  <form method="POST" class="bg-white p-4 rounded shadow-sm">

    <div class="mb-3">
      <label for="idpersona" class="form-label">ID Persona</label>
      <input type="text" class="form-control" name="idpersona" required>
    </div>

    <div class="mb-3">
      <label for="idhospital" class="form-label">ID Hospital</label>
      <select name="idhospital" class="form-select" required>
        <option value="">-- Selecciona un hospital --</option>
        <?php while ($row = pg_fetch_assoc($hospitales)) {
          echo "<option value='{$row['idhospital']}'>{$row['idhospital']}</option>";
        } ?>
      </select>
    </div>

    <div class="mb-3">
      <label for="planta" class="form-label">Planta</label>
      <input type="number" class="form-control" name="planta" required>
    </div>

    <div class="mb-3">
      <label for="habitacio" class="form-label">Habitación</label>
      <input type="number" class="form-control" name="habitacio" required>
    </div>

    <div class="mb-3">
      <label for="estat" class="form-label">Estado</label>
      <select name="estat" class="form-select" required>
        <option value="">-- Selecciona un estado --</option>
        <option value="lleu">Lleu</option>
        <option value="moderat">Moderat</option>
        <option value="greu">Greu</option>
        <option value="molt greu">Molt greu</option>
      </select>
    </div>

    <div class="mb-3">
      <label for="idvirus" class="form-label">ID Virus</label>
      <select name="idvirus" class="form-select" required>
        <option value="">-- Selecciona un virus --</option>
        <?php while ($row = pg_fetch_assoc($virus)) {
          echo "<option value='{$row['idvirus']}'>{$row['idvirus']}</option>";
        } ?>
      </select>
    </div>

    <button type="submit" name="enviar" class="btn btn-success">Ingresar</button>
  </form>
</div> <!-- cierre del container -->

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
  $(document).ready(function () {
    setTimeout(function () {
      $('.alert').fadeOut('slow');
    }, 4000);
  });
</script>

</body>

</html>
