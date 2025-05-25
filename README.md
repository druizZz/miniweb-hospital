# miniweb-hospital

# 🏥 MiniWeb Hospital

Este proyecto es una miniaplicación web de gestión hospitalaria desarrollada con **PHP**, **PostgreSQL** y **Bootstrap**.

Permite:

- Ingresar pacientes según su estado.
- Revisar y actualizar el estado de los pacientes.
- Gestionar el stock de vacunas.
- Visualizar historiales de vacunación.
- Probar triggers y funciones PL/pgSQL (como `revisapacient`, `ficastock`, `hospitalproper`, etc).

---

## 📁 Estructura del proyecto

hospital/
├── cartilla.php
├── conexion.php
├── header.php
├── index.php
├── ingresar.php
├── img/
└── hospital.sql <-- Base de datos exportada


---

## 🗄️ Base de Datos

El archivo `hospital.sql` contiene toda la estructura de tablas, funciones, triggers y datos iniciales del proyecto.

### ▶️ Para importar:

```bash
psql -U postgres -d hospital -f hospital.sql

⚙️ Tecnologías utilizadas
PostgreSQL (con funciones PL/pgSQL)

PHP

HTML5 + CSS3 (Bootstrap 5)

FileZilla (para subir al servidor)

Git y GitHub (control de versiones)

🧪 Cómo probar
1. Clona el proyecto o súbelo a un servidor con Apache:

   git clone https://github.com/druizZz/miniweb-hospital.git

2. Importa la base de datos como se explicó arriba.

3. Abre index.php desde el navegador (o vía Ngrok para compartirlo online).

4. Empieza a interactuar: ingresar pacientes, cambiar estados, vacunar, etc.
