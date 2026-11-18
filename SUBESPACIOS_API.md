# Subespacios (jerarquía de espacios) — Solicitud para el equipo de API

## Mensaje para copiar y enviar

> Hola. Necesitamos agregar **subespacios ilimitados** dentro de los espacios del inventario. Hoy la jerarquía es `section → space → item`; requerimos que un `space` pueda tener un `space` padre (`parent_space_id`) y que los objetos puedan seguir guardándose tanto en el espacio padre como en cualquier subespacio.
>
> La app Flutter ya está preparada para:
> - Enviar `parent_space_id` al crear/editar espacios.
> - Leer `parent_space_id`, `parentSpaceId` o `parent.id`.
> - Armar el árbol completo en el cliente.
>
> Necesitamos que la API implemente el campo, las validaciones (misma sección, sin ciclos, sin límite de niveles), el borrado en cascada de subespacios y sus objetos, y que devuelva el campo en los GET de espacios. Adjunto el detalle completo con DDL, endpoints, validaciones y ejemplos. Gracias.

---

## 1. Objetivo

Permitir árboles de espacios de profundidad ilimitada:

```text
Section (apartado)
  └── Space raíz (espacio)
        ├── Item (objetos directos)
        └── Space hijo (subespacio)
              ├── Item
              └── Space nieto (subespacio)
```

Requisitos funcionales:

- Un espacio puede contener objetos y subespacios al mismo tiempo.
- Un subespacio puede contener objetos y más subespacios.
- No hay límite de profundidad.
- Un subespacio siempre pertenece al mismo apartado que su padre.
- Los objetos pueden transferirse a cualquier espacio o subespacio del mismo apartado.
- Al eliminar un espacio se eliminan todos sus descendientes y sus objetos.

---

## 2. Cambio de esquema

### 2.1 Columna nueva

```sql
ALTER TABLE spaces
  ADD COLUMN parent_space_id UUID REFERENCES spaces(id) ON DELETE CASCADE;
```

- `NULL` = espacio raíz.
- El padre debe existir y tener el mismo `section_id`.
- `ON DELETE CASCADE` para que al borrar un padre se borren sus descendientes.
- Índice recomendado:

```sql
CREATE INDEX ix_spaces_parent ON spaces (parent_space_id);
```

> En MySQL 8 usar `CHAR(36)` para el UUID. En SQLite usar `TEXT`.

### 2.2 Validaciones obligatorias

En `POST /spaces` y `PATCH /spaces/{id}`:

1. `parent_space_id` puede ser `null`.
2. Si viene informado, el padre debe existir.
3. El padre debe tener el mismo `section_id` que el espacio.
4. Un espacio no puede ser su propio padre.
5. No se pueden crear ciclos: el nuevo padre no puede ser descendiente del espacio que se edita.
6. No hay límite de profundidad.
7. Si se cambia `section_id`, el subárbol completo debe moverse a la nueva sección de forma atómica; `parent_space_id` debe pertenecer a la nueva sección o quedar `null`.

Sugerencia de error:

```json
{
  "error": {
    "code": "INVALID_SPACE_PARENT",
    "message": "El espacio padre debe existir, pertenecer al mismo apartado y no generar un ciclo."
  }
}
```

---

## 3. Contrato JSON

La app envía y espera `parent_space_id` (snake_case). También acepta
`parentSpaceId` o `parent.id` en las respuestas.

### 3.1 Respuesta de un espacio

```json
{
  "id": 12,
  "section_id": 3,
  "parent_space_id": 8,
  "name": "Cajón A",
  "description": "Caja de cables",
  "emoji": "📦",
  "image_url": null,
  "item_count": 4,
  "subspace_count": 2,
  "total_item_count": 9,
  "created_at": "2026-11-18T15:00:00Z",
  "updated_at": "2026-11-18T15:00:00Z"
}
```

Campos de conteo (recomendados, no bloqueantes):

- `item_count`: objetos guardados directamente en el espacio.
- `subspace_count`: subespacios directos.
- `total_item_count`: objetos del espacio y de todos sus descendientes.
- La app también puede calcularlos, pero enviarlos evita trabajo y mantiene
  consistencia entre clientes.

Opcional, para conveniencia:

```json
"parent": { "id": 8, "name": "Sala 1", "emoji": "🏢" }
```

### 3.2 Crear espacio

`POST /spaces`

```json
{
  "section_id": 3,
  "parent_space_id": 8,
  "name": "Cajón A",
  "description": "Caja de cables",
  "emoji": "📦",
  "image_url": null
}
```

- `parent_space_id` es opcional.
- Si se omite o es `null`, se crea un espacio raíz.

### 3.3 Editar espacio

`PATCH /spaces/{id}`

```json
{
  "parent_space_id": 12,
  "name": "Cajón A - Cables"
}
```

- Enviar `parent_space_id: null` mueve el espacio a raíz.
- El campo solo debe actualizarse si viene en el body.
- Validar ciclos y misma sección.

---

## 4. Endpoints afectados

### `GET /sections/{sectionId}/spaces`

Debe devolver **todos** los espacios de la sección, incluidos los subespacios,
con `parent_space_id`, para que la app arme el árbol. Mantener paginación
actual.

Opcional: aceptar `parent_space_id` como filtro para cargar solo hijos de un
espacio.

### `GET /spaces/{id}`

Debe incluir `parent_space_id` y, si se implementa, el objeto `parent`.

### `POST /spaces`

Aceptar `parent_space_id`.

### `PATCH /spaces/{id}`

Aceptar `parent_space_id`, validar ciclos y misma sección.

### `DELETE /spaces/{id}`

Debe eliminar el espacio, todos sus subespacios y todos los objetos de todo el
subárbol.

Reglas para revisiones activas:

- Cerrar las revisiones activas de todos los objetos del subárbol.
- `exit_reason` recomendado: `'Espacio eliminado'` (o
  `'Subespacio eliminado'` si se prefiere distinguir).
- Conservar los snapshots de `review_history`.

La respuesta sigue siendo `204` sin cuerpo.

### `POST /items/{id}/transfer`

Sin cambios de contrato. Mantener la validación actual: el destino debe existir,
pertenecer al mismo apartado y ser distinto del espacio actual. Ahora también
puede ser un subespacio.

### `GET /items` y `GET /history/*`

Sin cambios obligatorios. Si se agrega `space_path` a los snapshots de
revisiones, la app podrá mostrar la ruta completa; no es bloqueante.

---

## 5. Métricas

`GET /metrics`:

- `totals.spaces` debe contar **todos** los espacios, incluidos subespacios.
- `bySection[].spaces` igual.
- Opcional: agregar `totals.root_spaces` y `totals.subspaces`, y lo mismo por
  apartado, para mostrar el desglose sin cálculos adicionales.
- `totals.items`, `totalValue` e `inReview` no cambian.

---

## 6. Ejemplos de árbol

```text
Oficina (section)
  ├── Sala 1 (space, parent_space_id = null)
  │     ├── Laptop Dell (item)
  │     ├── Cajón A (space, parent_space_id = Sala 1)
  │     │     ├── Cable HDMI (item)
  │     │     └── Caja 3 (space, parent_space_id = Cajón A)
  │     │           └── Adaptador USB-C (item)
  │     └── Cajón B (space, parent_space_id = Sala 1)
  └── Sala 2 (space, parent_space_id = null)
```

---

## 7. Checklist de aceptación para la API

- [ ] Migración con `parent_space_id` e índice.
- [ ] `POST /spaces` acepta `parent_space_id` y lo devuelve.
- [ ] `PATCH /spaces/{id}` permite cambiar o quitar el padre.
- [ ] `GET /sections/{sectionId}/spaces` devuelve todos los espacios con
      `parent_space_id`.
- [ ] `GET /spaces/{id}` devuelve `parent_space_id`.
- [ ] Se rechaza padre de otra sección, auto-padre y ciclos.
- [ ] Se permite profundidad ilimitada.
- [ ] Al borrar un espacio se borran subespacios, objetos y se cierran sus
      revisiones activas.
- [ ] Al mover un espacio de sección se mueve todo su subárbol.
- [ ] Transferencia de objetos funciona entre espacios y subespacios del mismo
      apartado.
- [ ] Métricas cuentan todos los espacios.
- [ ] Pruebas con al menos 3 niveles y dos subárboles hermanos.

---

## 8. Nota sobre la app

La app ya implementa:

- `parent_space_id` en el modelo, caché local y requests.
- Árbol de espacios con profundidad ilimitada.
- Crear subespacio desde un espacio.
- Editar el espacio padre y bloquear ciclos en el cliente.
- Borrado local de descendientes mientras la API responde.
- Contadores: objetos directos, subespacios y objetos totales.
- Etiquetas con ruta completa (`Sala 1 / Cajón A / Caja 3`).
- Transferencias a cualquier espacio del mismo apartado.

Mientras la API no implemente el campo, la app seguirá funcionando con los
espacios planos; los subespacios creados se verán como espacios raíz hasta que
el backend los persista.
