# 🏥 MiniWeb Hospital

Este proyecto es una miniaplicación web de gestión hospitalaria desarrollada con **PHP**, **PostgreSQL** y **Bootstrap**.

Permite:

- Ingresar pacientes según su estado.
- Revisar y actualizar el estado de los pacientes.
- Gestionar el stock de vacunas.
- Visualizar historiales de vacunación.
- Probar triggers y funciones PL/pgSQL (`revisapacient`, `ficastock`, `hospitalproper`, etc).

---

## 📁 Estructura del proyecto

```bash
hospital/
├── cartilla.php
├── conexion.php
├── header.php
├── index.php
├── ingresar.php
├── img/
└── hospital.sql  <-- Base de datos exportada
```

---

## 🗄️ Base de Datos

El archivo `hospital.sql` contiene toda la estructura de tablas, funciones, triggers y datos iniciales del proyecto.

### ▶️ Importar la base de datos:

```bash
psql -U postgres -d hospital -f hospital.sql
```

---

## ⚙️ Tecnologías utilizadas

- PostgreSQL (con funciones PL/pgSQL)
- PHP
- HTML5 + CSS3 (Bootstrap 5)
- FileZilla (para subir al servidor)
- Git y GitHub (control de versiones)

---

## 🌍 Proyecto desplegado

[https://deee-81-184-33-23.ngrok-free.app/hospital/ingresar.php](https://deee-81-184-33-23.ngrok-free.app/hospital/)

---

## 👤 Autor

David Ruiz  
Proyecto realizado como parte del módulo de **Bases de Dades**  
CFGS DAW - 2025
