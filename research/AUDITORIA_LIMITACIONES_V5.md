# Auditoría de limitaciones — Filtro de Realidad v5 + Anti-Sycophancy (release v1.5.0)

**Fecha:** 2026-10-11. **Base auditada:** `main` @ `9997b90` (clon de
`github.com/RuizHernandez/reality-filter-protocol`). **Rama de trabajo:** `audit/limitaciones-v5`
(local; sin push). **Entorno:** Windows 11 Pro 10.0.26200, Git Bash (MSYS2, bash 5.3.15),
git 2.55.0.windows.3, jq 1.7.1 (binario oficial descargado a la carpeta temporal de la sesión con
autorización del usuario; SHA-256 verificado contra `sha256sum.txt` del release).

**Autoría y revisión.** Auditoría ejecutada por una sola instancia de agente (Claude). La única
revisión independiente es la de un subagente revisor de código con contexto separado sobre el
diff final (ver `RESULTADOS_Y_EVIDENCIAS.md` §7). Ambos pertenecen a la misma familia de
modelos: su independencia es operativa, **no estadística** (L7 aplicada a esta misma auditoría).

## Leyenda de estados

| Estado | Significado en este documento |
|---|---|
| **DEMOSTRADO** | Respaldado por una ejecución registrada (comando, salida, artefacto). |
| **IMPLEMENTADO SIN VALIDACIÓN SUFICIENTE** | Existe código o texto, pero la evidencia no alcanza para el resultado deseado. |
| **PROPUESTO** | Diseñado aquí, no implementado. |
| **FALLIDO** | Se ejecutó una comprobación y no superó su criterio. |
| **NO VERIFICABLE** | Sin acceso, infraestructura o datos para resolverlo. |

Cada hallazgo distingue tres niveles: **(A)** existencia de la implementación; **(B)** funcionamiento
técnico conforme a requisitos; **(C)** eficacia experimental sobre el comportamiento de un LLM.
Ninguna prueba de esta auditoría alcanza el nivel C.

---

## 1. Línea base

### 1.1 Arquitectura real

El repositorio es, ante todo, **texto normativo** (`PROTOCOL.md`, §1–§6) replicado en adaptadores
por plataforma (`adapters/`), más una **capa de verificación determinista** escrita en shell:

| Capa | Componentes | Naturaleza |
|---|---|---|
| Norma | `PROTOCOL.md`, `adapters/*`, `examples/*` | Instrucciones en lenguaje natural para el modelo |
| Controles de artefacto | `validation/hooks/*` (pre-commit / commit-msg) | Ejecutables, fuera del modelo |
| Checkers | `validation/lib/*` (pares §3.12, secretos, dependencias, entregables, stash, linter, mutación) | Ejecutables, fuera del modelo |
| Suites | `validation/replay_incident.sh`, `peer_verification_suite.sh`, `skill_gates_suite.sh` | Pruebas sintéticas sin LLM |
| Coherencia documental | `scripts/sync-check.sh`, `check-citations.sh`, `check-claims.sh`, `adapter-coverage.sh` | CI (`.github/workflows/*.yml`) |
| Aparato experimental | `validation/ab-study/*` | Diseño + runner; **sin datos** |

No hay ningún componente que ejecute un LLM en la CI. La única ejecución con modelo real es
`validation/live-agent-trial-1/` (N=1, Cursor CLI, 2026-08-05).

### 1.2 Las cuatro etiquetas epistémicas (definición original, sin modificar)

`PROTOCOL.md` §2: `[E]`/`[Empirical]` (respaldada por un artefacto verificable citado),
`[I]`/`[Inference]` (deducción lógica a partir de premisas empíricas etiquetadas; se expone la
cadena), `[S]`/`[Speculation]` (plausible, no implicada por la evidencia comprobada),
`[U]`/`[Unverified]` (no confirmable tras una búsqueda real). §3.12 declara que las cuatro son el
conjunto completo. Esta auditoría **no altera** ni los nombres ni las definiciones.

### 1.3 Inventario de mecanismos declarados y su estado inicial

| Mecanismo declarado | (A) Existe | (B) Funciona técnicamente | (C) Eficacia en LLM |
|---|---|---|---|
| Anti-sycophancy bidireccional (§1) | Solo instrucción; linter heurístico `anti_sycophancy_check.sh` sin pruebas ni uso en CI | **FALLIDO** (falso negativo por diseño, ver L-AS) | NO VERIFICABLE (sin A/B) |
| Cuatro etiquetas (§2) | Solo instrucción | Sin control estructural | NO VERIFICABLE |
| Separación evidencia/inferencia/especulación | Solo instrucción | Sin control | NO VERIFICABLE |
| Caducidad de evidencia (§2, v1.5.0) | Solo instrucción | Sin control | NO VERIFICABLE |
| Verificación entre pares (§3.12) | `peer_verification_check.sh` + 8 fixtures | DEMOSTRADO para los 8 escenarios, con defecto de alcance (L7) | NO VERIFICABLE |
| Controles de artefacto (§3.1/3.2/3.3/3.8/3.10) | Hooks + 13 escenarios | DEMOSTRADO bajo condiciones (ruta corta); defectos adversariales (L6) | 1 ensayo N=1 |
| Verificación de citas | `check-citations.sh` | DEMOSTRADO para **existencia**; no verifica correspondencia (L2) | — |
| Mutation testing (`mutate_check.sh`) | Existe | **FALLIDO**: inerte (ninguna suite leía la variable de sustitución) | — |
| Preregistro A/B | `preregister.sh`, `runner.sh` | IMPLEMENTADO SIN VALIDACIÓN: el runner no comparaba hashes | Sin datos |

### 1.4 Reproducción de los antecedentes 13/13, 8/8, 13/13

| Suite | Registro histórico | Reproducción en esta auditoría | Estado |
|---|---|---|---|
| `replay_incident.sh` | `validation/replay_run_2026-08-05.log` (13/13) | 13/13 **solo** con directorio temporal corto; con ruta larga: 5 PASS / 8 FAIL sin crear repositorio | DEMOSTRADO bajo condiciones; oráculo **FALLIDO** (falsos PASS) |
| `peer_verification_suite.sh` | `validation/peer_run_2026-08-26.log` (8/8) | 8/8 con `jq`; sin `jq`: 2/8, y los 2 PASS (PV7/PV8) eran vacíos | DEMOSTRADO bajo condiciones; oráculo **FALLIDO** sin jq |
| `skill_gates_suite.sh` | `validation/gates_run_2026-08-27.log` (13/13) | 13/13 | DEMOSTRADO |

Los tres resultados son **(B)**: comprueban controles de artefacto, no modelos. Los registros
históricos no fijan entorno (SO, versiones, ruta), por lo que la reproducibilidad dependía de
condiciones no documentadas.

### 1.5 Riesgos prioritarios detectados en la línea base

1. **Oráculos que aceptan cualquier fallo como rechazo del control** (replay, suite de pares).
2. **Hooks con vías de evasión** (rutas con espacios, renombrado de la especificación, checker
   ausente → permitir, hook muerto por señal = éxito en Git for Windows).
3. **Verificación bibliográfica limitada a la existencia** de la fuente.
4. **Herramientas de calidad inertes o débiles** (`mutate_check.sh`, linter anti-sycophancy).
5. **Aparato A/B sin integridad de preregistro ni ciego completo.**
6. **Ausencia total de evidencia conductual controlada** (riesgo científico, no técnico).

---

## 2. Diagnóstico por limitación

### L2 — Fuente auténtica con información incorrecta

- **Mecanismo existente.** `scripts/check-citations.sh` + `scripts/citations.tsv`: verifica que el
  identificador resuelve (arXiv/Crossref/IETF) y que coincide un fragmento del título.
  **Comprueba existencia, no correspondencia.**
- **Evidencia.** Se releyeron los resúmenes primarios de las tres fuentes con cifras atribuidas
  (arXiv API; página de *Scientific Reports*). De seis afirmaciones cuantitativas, cuatro están
  respaldadas a nivel de resumen y **dos son parciales**: "as low as 53.9%" (Young 2026)
  presenta como mínimo lo que es una tasa agregada (el mínimo por modelo del resumen es 39,7 %);
  "Best-of-N/RAG amplify rather than mitigate" (Kraidia 2026) elimina el modal "*can*
  unintentionally amplify". Sin avisos de corrección/retractación en Crossref para los DOI
  consultados (ausencia en Crossref ≠ prueba de inexistencia).
- **Modificación.** `scripts/check-claim-support.sh` + `scripts/claim-support.tsv`: registro de
  procedencia (versión de la fuente, localizador, fecha, método) y estado de correspondencia
  (SUPPORTED / PARTIAL / NOT_SUPPORTED / CONTRADICTED / NOT_CHECKED); falla si una cifra del
  apartado bibliográfico no está registrada, si una fila queda obsoleta, o si hay
  NOT_SUPPORTED/CONTRADICTED; `--online` relee resúmenes arXiv (deriva de versión, retirada) y
  consulta avisos de Crossref.
- **Estado.** (A) sí; (B) **DEMOSTRADO** (AU-C1…C6); la distinción existencia ≠ respaldo ≠ verdad
  queda explícita en la salida. La comprobación de retractación es **parcial**: depende de
  Crossref/arXiv; otras vías (bases de retractaciones, avisos editoriales) quedan sin cubrir.
- **Riesgo residual.** El respaldo se comprobó a nivel de **resumen**; texto completo no auditado.
  El estado lo asigna una persona o agente, no la herramienta. Cifras sin `%` ni separador de
  miles ("12 modelos") no se detectan automáticamente.

### L3 — Búsqueda incompleta

- **Mecanismo existente.** §2 "Exhaustive search before declaring ignorance" y la definición de
  `[U]`. Sin registro de consultas, fuentes ni cobertura; sin control externo. La skill
  `cybersecurity` sí formula "no se encontraron vulnerabilidades es un enunciado sobre la
  cobertura" (texto, no control).
- **Modificación.** `validation/lib/epistemic_label_check.sh`, reglas **R4** (`[U]` exige registro
  de búsqueda: consultas, fuentes examinadas, enunciado de cobertura, ≥2 consultas distintas o
  razón explícita) y **R5** (toda afirmación de ausencia exige registro de búsqueda; nunca se
  admite ausencia universal).
- **Estado.** (B) **DEMOSTRADO** sobre fixtures (AU-L5–L8). (C) NO VERIFICABLE. Ningún adaptador
  emite todavía transcripciones en ese esquema: el control existe, pero **no está conectado** a
  una plataforma real.
- **Riesgo residual.** El checker verifica que el registro exista, no que la búsqueda haya sido
  adecuada. Conjuntos documentales con fuentes relevantes conocidas (recall de búsqueda) quedan
  como tarea experimental (T6 en `PLAN_EXPERIMENTAL_AB.md`).

### L4 — Costo computacional

- **Operaciones reales.** El costo del protocolo tiene dos partes: (i) **contexto**: `PROTOCOL.md`
  ocupa 21 981 bytes / 3 080 palabras (§3 = 7 418 bytes, la sección más larga); adaptadores entre
  2 806 y 6 141 bytes; (ii) **verificación**: lecturas/ejecuciones adicionales que el protocolo
  pide al agente, no medibles sin LLM. Los controles deterministas son baratos (tiempos en
  `RESULTADOS_Y_EVIDENCIAS.md` §4: 1–7 s por suite; 29 s la suite de auditoría; 0,4 s frente a
  4,2 s el checker de respaldo sin/con red).
- **Mecanismo adaptativo existente.** Solo dos: caché de 7 días en `check-citations.sh --online`
  (vigencia de comprobaciones previas) y la regla "no re-etiquetado redundante" (v1.3.0).
- **Estado.** Costo de contexto **DEMOSTRADO** (medido en bytes; tokens solo estimables sin
  tokenizador). Costo conductual (tokens, latencia, llamadas a herramientas, errores no detectados)
  **NO VERIFICABLE** sin ejecuciones con modelo; el runner A/B registra ahora `prompt_bytes`,
  `prefix_bytes` y `wall_seconds` por corrida. Un esquema de verificación adaptativa por riesgo
  queda **PROPUESTO** (`ARQUITECTURA_Y_CAMBIOS.md` §5); no se implementó porque, sin datos de costo
  y calidad, cualquier umbral sería arbitrario.

### L5 — Ambigüedad epistémica

- **Mecanismo existente.** Definiciones de §2 en prosa; regla "etiquetar el punto donde cambia el
  nivel de evidencia". Sin reglas de descomposición ni resolución de afirmaciones compuestas, sin
  medidas de concordancia, sin control de etiquetas inválidas.
- **Modificación.** `epistemic_label_check.sh` R1 (vocabulario cerrado: las cuatro etiquetas,
  forma corta o larga), R2 (`[E]` exige artefacto), R3 (`[I]` exige premisas `[E]`/`[I]`; una
  inferencia desde `[S]`/`[U]` es `[S]`), R6 (una afirmación compuesta no puede ser más fuerte
  que su parte más débil: E > I > S,U). Fixtures positivos, negativos y fronterizos en
  `validation/fixtures/epistemic/`.
- **Corrección tras la revisión independiente.** La primera versión del checker aceptaba un `[E]`
  "lavado" mediante `restates` (re-afirmación de un `[S]` o del `[E]` de un par), cadenas vacías
  como evidencia, ausencias sin `absence_scope` y transcripciones sin ninguna afirmación. Corregido
  y cubierto por AU-L13–L17.
- **Estado.** (B) **DEMOSTRADO** (AU-L1–L4, AU-L9, AU-L13–L17). Compatibilidad con el protocolo original:
  las reglas operacionalizan definiciones existentes; **R6 y el umbral "≥2 consultas" de R4 son
  operacionalizaciones nuevas** y se proponen como enmienda, no se dan por normativas.
  Concordancia entre evaluadores y métricas de clasificación: **NO VERIFICABLE** (no existe un
  conjunto con etiquetas de referencia de dos anotadores); diseño en `PLAN_EXPERIMENTAL_AB.md` §8.
- **Riesgo residual.** El checker verifica la **forma** de una etiqueta, no que sea la correcta.

### L6 — Seguridad y cumplimiento

- **Clasificación de reglas** (detalle en `MATRIZ_TRAZABILIDAD.md` §2): de las reglas de §1–§6,
  solo §3.1 (lectura por SHA, mecanismo), §3.2, §3.3 (localización), §3.8, §3.10, §3.12 (forma),
  §2 (forma de etiquetas y caducidad, desde esta auditoría) y §4.1 (en los checkers) tienen un
  control externo; el resto depende **solo de instrucciones**.
- **Defectos demostrados en controles externos** (pruebas adversariales locales, no destructivas,
  en repositorios desechables):
  1. Credencial en una ruta con espacio → **commit aceptado sin escanear** (`for path in $staged`).
  2. Checker de secretos ausente → hook **permite** (`exit 0`), contrario a §4.1.
  3. Especificación protegida renombrada por un Coder → **aceptado** (detección de renombres).
  4. Especificación protegida con espacio en la ruta → **aceptada**.
  5. **Git for Windows 2.55 trata un hook terminado por señal como éxito** (SIGPIPE/SIGTERM →
     commit aceptado; `exit 1` sí bloquea). Un pipe de stderr cerrado convertía un rechazo en
     commit.
  6. *(Hallado por el revisor independiente, no por esta auditoría.)* El hook de inmutabilidad
     iteraba sus patrones sin entrecomillar y el shell los expandía contra el árbol de trabajo:
     con una segunda especificación presente, **borrar o renombrar la primera no coincidía con
     ningún patrón**. Defecto preexistente en `main`; la primera versión de esta auditoría lo dio
     por resuelto con `--no-renames`, porque AU-H5 usaba un repositorio con una sola especificación.
- **Modificación.** Rutas delimitadas por NUL y sin detección de renombres; `set -f` en el bucle
  de patrones; listado de rutas por archivo temporal (un fallo de `git diff` ya no se lee como
  "nada en staging"); *fail-closed* si falta el checker o un blob no se puede leer; `trap '' PIPE`
  en los cuatro hooks.
- **Estado.** (B) **DEMOSTRADO** (AU-H1–H10; ocho de ellos fallan con los hooks originales por
  defectos reales, y AU-H6 por efecto de secuencia).
  **Riesgos residuales:** SIGTERM/SIGKILL siguen fuera del alcance de un hook cliente; `AGENT_ROLE`
  sigue siendo una variable de entorno autodeclarada (limitación ya reconocida en `REPORT.md`);
  los hooks son eliminables por quien tenga shell (`--no-verify`). La protección frente a
  **inyección de instrucciones** no existe ni como texto en `PROTOCOL.md` (solo en la skill
  `cybersecurity`, para código no confiable): **PROPUESTO** como enmienda; ningún control
  determinista local puede demostrar su eficacia sin LLM.

### L7 — Dependencia entre agentes

- **Mecanismo existente.** §3.12 (independencia de artefacto y método; consenso ≠ verificación) y
  `peer_verification_check.sh`.
- **Defecto demostrado.** La comparación de alcance era por subcadena: `cat old_impl.py.bak` se
  aceptaba como lectura de `impl.py` (AU-P1).
- **Modificación.** Coincidencia por token de ruta; mensaje de rechazo específico
  ("ninguno de sus comandos lee ese artefacto"); **nota de dependencia** cuando el receptor
  verifica con el mismo comando que un par (re-ejecución válida según §3.1, pero no método
  independiente). Limpieza de `\r` (jq de Windows contaminaba el registro: `"analyst-a\r"`).
  Tras la revisión independiente: los comandos que solo nombran el archivo (`ls`, `echo`, `wc`,
  `touch`…) no cuentan como lectura (AU-P4), y se reconocen más lecturas truncadas (`sed -E -n`,
  `sed 5q`, `awk NR==`, `<(head …)`; AU-P5). La lista sigue siendo heurística.
- **Independencia en tres dimensiones.** *Operativa:* el checker distingue lectura propia vs.
  heredada (**DEMOSTRADO**, B). *Documental:* solo se detecta la coincidencia literal de comando;
  la diversidad de **fuentes** no se modela (**PROPUESTO**). *Estadística:* **NO VERIFICABLE**; no
  hay datos de errores conjuntos; diseño en `PLAN_EXPERIMENTAL_AB.md` §7 (T7, correlación φ de
  errores entre verificadores por configuración).
- **Riesgo residual.** Dos agentes del mismo modelo que leen el mismo artefacto defectuoso
  "verifican" correctamente según §3.12 y comparten el error: el protocolo garantiza lectura
  propia, no independencia de error.

### L8 — Evolución temporal y reproducibilidad

- **Hallazgos.** (i) Los registros de ejecución no fijaban entorno; los resultados dependían de la
  longitud de ruta y de `jq` (§1.4). (ii) `runner.sh` registraba el blob de `HEAD`, no el archivo
  realmente usado, y no verificaba los hashes del preregistro. (iii) No se registraba el
  identificador exacto del modelo (el ensayo N=1 usó `auto`). (iv) README y README.es citaban un
  DOI de v1.0.0 como "último"; verificado contra la API de Zenodo: v1.5.0 =
  `10.5281/zenodo.22256185`, DOI concepto = `10.5281/zenodo.21499993`. (v) `jq.exe` nativo no abre
  rutas relativas que, virtualizadas, superan 260 caracteres (fallo ambiental; el checker
  respondió *fail-closed*).
- **Modificación.** `validation/run_all.sh` (huella de entorno + tiempos por paso);
  `validation/audit_run_2026-10-11.log` fechado y registrado en `sync-check.sh`; runner con
  verificación de hashes, `AB_MODEL_ID` obligatorio, `prompt_sha256`, `runner_sha256`,
  corridas *append-only*; README corregidos.
- **Estado.** (B) **DEMOSTRADO** para el aparato (AU-AB1–AB6). Reproducibilidad de **modelos
  remotos**: NO VERIFICABLE por naturaleza (los proveedores cambian modelos bajo el mismo nombre);
  mitigación = registrar identificador, fecha y parámetros, y tratar cada resultado como
  condicionado a ellos.

### L-AS — Mecanismos Anti-Sycophancy (preservados)

`anti_sycophancy_check.sh` contaba como fundamento **cualquier** `TOOL:` anterior del transcript (un
`ls` en el turno 1 validaba un "LGTM" no leído en el turno 5). Se restringió al turno actual
(AU-S2). Se conservaron las tres reglas (M1, M2, FAB-OBJECTION) y se añadieron pruebas en ambas
direcciones: aprobación sin fundamento (AU-S2, S3), objeción fabricada (AU-S4) y **revisión crítica
fundamentada que no debe marcarse** (AU-S5). Sigue siendo heurístico (cualquier herramienta en el
turno cuenta); no sustituye la calificación ciega del A/B.

---

## 3. Matriz de decisión (Fase 3)

Escala 1–3 (3 = alto).

| Cambio | Lim. | Gravedad | Impacto científico | Evidencia de deficiencia | Esfuerzo | Validable localmente | Riesgo regresión | Decisión |
|---|---|---|---|---|---|---|---|---|
| Oráculo con etiqueta + preflight (suites) | L8/L6 | 3 | 3 | 3 (demostrado) | 1 | sí | 1 | **Implementado** |
| Hooks: NUL, sin renombres, fail-closed, SIGPIPE | L6 | 3 | 2 | 3 | 1 | sí | 1 | **Implementado** |
| Checker §3.12: token de ruta + nota de dependencia | L7 | 2 | 2 | 3 | 1 | sí | 1 | **Implementado** |
| Mutation testing operativo | L8 | 2 | 2 | 3 | 1 | sí | 1 | **Implementado** |
| Registro de respaldo documental | L2 | 2 | 3 | 3 | 2 | sí | 1 | **Implementado** |
| Checker de estructura epistémica + caducidad | L3/L5 | 2 | 3 | 2 (ausencia de control) | 2 | sí (fixtures) | 1 | **Implementado** |
| Integridad de preregistro, ciego, placebo, ablaciones | L8/A-B | 3 | 3 | 3 | 2 | sí (agente simulado) | 1 | **Implementado** |
| Linter anti-sycophancy por turno | L-AS | 1 | 1 | 3 | 1 | sí | 1 | **Implementado** |
| Enmiendas al texto de `PROTOCOL.md` | L2–L7 | 2 | 2 | 2 | 1 | no (requiere release y re-sync de adaptadores) | 2 | **Propuesto** |
| Verificación adaptativa por riesgo | L4 | 2 | 2 | 1 (sin datos) | 3 | no | 2 | **Propuesto** |
| Conectar checkers a una plataforma real | L3/L5/L7 | 3 | 3 | 2 | 3 | no | 2 | **Aplazado** (sin plataforma con transcripciones estructuradas) |
| Control del lado servidor (branch protection) | L6 | 3 | 2 | 2 | 1 | no (operación externa) | 1 | **Bloqueado**: requiere autorización sobre el repositorio remoto |

---

## 4. Lista verificable de tareas

**Completadas**
- [x] Línea base: inventario, ejecución de las tres suites y de los checks documentales, causa de los fallos ambientales.
- [x] Diagnóstico de L2–L8 contra código y documentación.
- [x] Modificaciones locales con 53 escenarios nuevos (lista exacta de archivos en `ARQUITECTURA_Y_CAMBIOS.md` §3).
- [x] Comparación antes/después (OFAT por archivo): 27 de 53 escenarios fallan con los archivos originales.
- [x] Regresión: 13/13, 8/8, 13/13 sin cambio de recuento; checks documentales en verde.
- [x] Mutación: todos los mutantes aplicables eliminados en los cuatro checkers.
- [x] Plan A/B prerregistrable con ablaciones (`PLAN_EXPERIMENTAL_AB.md`).
- [x] Revisión del texto científico disponible en el repositorio (`TEXTO_CIENTIFICO_REVISADO.md`).
- [x] Revisión independiente del diff por un subagente de contexto separado (resultados y resolución en `RESULTADOS_Y_EVIDENCIAS.md` §7).

**Bloqueadas o aplazadas (con causa)**
- [ ] Ejecución del A/B con modelos — *bloqueada*: requiere autorización de gasto en API y elección de modelos.
- [ ] Verificación en CI de GitHub — *bloqueada*: requiere push (no autorizado).
- [ ] Protección de rama/estado requerido en el remoto — *bloqueada*: operación externa sobre el repositorio.
- [ ] Concordancia entre anotadores (L5) — *bloqueada*: requiere dos anotadores humanos.
- [ ] Respaldo a texto completo (L2) — *aplazada*: se auditó a nivel de resumen.
- [ ] Enmiendas a `PROTOCOL.md` — *aplazadas a decisión del autor*: cambian el texto canónico, exigen release y re-sincronización de adaptadores; la misión prohíbe incrementar la versión automáticamente.
- [ ] Revisión del manuscrito externo ("companion research paper") — *no verificable*: no está en el repositorio.
