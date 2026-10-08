# AGENT.MD

> **Proyecto:** EntregaYa — Rastreo de paquetes, firma digital y liquidación de choferes
> **Objetivo:** Guía de desarrollo y especificación técnica para montar el prototipo funcional/demo en **Flutter** (Web, PWA y Android APK).
> **Regla de Oro:** La demo debe completarse de principio a fin en **5 minutos sin errores ni configuraciones previas**. Todo el texto en español, moneda en USD ($) y fechas en formato `dd/mm/aaaa`.

---

## 1. Misión del Agente de Código

Como agente desarrollador, tu misión es construir el prototipo de **EntregaYa**. El sistema debe ser responsive (Desktop para Despachador/Admin, Móvil para Chofer y Tracking Público), multi-tenant estricto por `empresa_id` y disponer de accesos directos de login sin contraseña.

---

## 2. Puntos Clave de la Arquitectura Flutter

* **Plataformas Objetivo:**
  1. **Web / PWA:** Despliegue web responsive con manifiesto PWA e ícono para instalar en pantalla de inicio (iOS/Android).
  2. **Android APK:** Compilación nativa APK (vía Flutter nativo o exportación/wrapper) para uso en campo.
* **Gestión de Estado:** Provider, Riverpod o BLoC con almacenamiento local o API REST.
* **Mapas y Ubicación:** Utilizar OpenStreetMap (`flutter_map` / Leaflet) para evitar costos de API.
* **Firma Digital:** Plugin de captura táctil (`signature` / `hand_signature`).
* **Generación de Reportes:** Exportación a PDF/Excel (`pdf`, `excel`, `printing`).

---

## 3. Modelo de Datos y Script de Seed (`seed_data`)

La base de datos (o mock en memoria/API) debe ser multi-tenant (`empresa_id`) y poblarse mediante un script/botón de **"Restablecer datos demo"**.

### Datos Obligatorios del Seed:
1. **2 Empresas:** "Courier Demo Express" y "Distribución Demo Costa".
2. **Usuarios Demo con Botones Quick-Login:**
   * Administrador
   * Despachador (2 usuarios)
   * Choferes (8 choferes con sus vehículos/placas ficticias)
3. **Entidades ficticias con contexto ecuatoriano (ficticias):**
   * 30 Clientes (nombres, teléfonos `099 000 0000`, direcciones en Guayaquil, Quito, Cuenca, Manta).
   * 100 Paquetes en estados: `recibido`, `en_ruta`, `entregado`, `fallido` con códigos de tracking únicos.
   * 5 Rutas activas.
   * 2 semanas de liquidaciones calculadas.
   * Historial de 3 meses para gráficos y reportes.

---

## 4. Matriz de Roles y Permisos

| Rol | Vistas y Capacidades |
| :--- | :--- |
| **Administrador** | Control total: choferes, vehículos, comisiones, usuarios, reportes, restablecer datos demo. |
| **Despachador** | Registrar paquetes (genera link único/WS simulado), armar rutas, asignar choferes, aprobar liquidaciones. |
| **Chofer** | **Vista móvil limpia:** Ver ruta del día, cambiar estados, capturar firma dibujada + receptor, foto opcional, motivo de fallo, abrir mapas. |
| **Cliente** | **Página pública de tracking (Sin Login):** Línea de tiempo con estados del paquete. |

---

## 5. Guion de Demo (5 Minutos sin Fallos)

El flujo que debe poder ejecutarse para la prueba principal es:
1. **Paso 1:** Entrar como **Despachador** (un solo tap/click en el botón demo). Registrar un nuevo paquete y copiar/abrir el link de tracking.
2. **Paso 2:** Abrir el **Link de Tracking Público** en un móvil o pestaña simulada y verificar su estado e historial.
3. **Paso 3:** Entrar como **Chofer**, seleccionar la ruta activa, abrir el paquete registrado y **marcar como entregado** guardando la firma digital con el dedo y el nombre del receptor.
4. **Paso 4:** Refrescar el tracking público y constatar el cambio a `entregado` con su timestamp y firma.
5. **Paso 5:** Volver a la vista de **Despachador/Admin**, ir al módulo de **Liquidaciones** y verificar el cálculo automático de la comisión y neto a pagar.
6. **Paso 6:** Exportar el reporte de entregas a **PDF o Excel**.

---

## 6. Checklist de Aceptación Pre-Entrega

- [ ] Funciona en Web (móvil/desktop) y Android APK.
- [ ] Botones de inicio rápido para cada rol ("Entrar como Admin", "Entrar como Operativo", "Entrar como Chofer").
- [ ] Multi-tenant funcional (Empresa A no ve datos de Empresa B).
- [ ] Lienzo de firma táctil funcional que se visualiza en el detalle del paquete.
- [ ] Botón "Restablecer datos demo" para reiniciar la base al estado inicial.
- [ ] Exportación de reportes (PDF/Excel) funcional.