# Matriz de trazabilidad — auditoría 2026-10-11

Cadena por fila: **Limitación → Componente → Evidencia inicial → Modificación → Prueba → Resultado → Riesgo residual.**
"Antes" = la misma prueba ejecutada con el archivo de `main` @ `9997b90`; "Después" = rama
`audit/limitaciones-v5`. Registros: `validation/audit_run_2026-10-11.log` (después) y
`RESULTADOS_Y_EVIDENCIAS.md` §3 (antes/después). Todas las pruebas son de nivel (B), técnico; ninguna
mide comportamiento de un LLM.

## 1. Matriz

| Lim. | Componente | Evidencia inicial | Modificación | Prueba | Resultado (antes → después) | Riesgo residual |
|---|---|---|---|---|---|---|
| L2 | `scripts/check-citations.sh` | Solo existencia del identificador + título; 2 de 6 cifras citadas resultan PARCIALES frente al resumen primario | Nuevo `scripts/check-claim-support.sh` + `scripts/claim-support.tsv` (procedencia, estado de respaldo, `--online` con deriva de versión, retirada y avisos Crossref) | AU-C1…C6 | control inexistente → 6 de 6 | Solo nivel de resumen; estado asignado por persona/agente; cifras sin `%` o miles no detectadas; retractaciones fuera de Crossref/arXiv no cubiertas |
| L2 | `PROTOCOL.md` "Grounded in research" | C2 "as low as 53.9%" y C5 "amplify rather than mitigate" sobredimensionan la fuente | **Propuesta** de redacción (`TEXTO_CIENTIFICO_REVISADO.md` §3); no aplicada al texto canónico | `check-claim-support.sh` reporta 2 de deuda | — | Persisten hasta que el autor decida una release |
| L3 | §2 "Exhaustive search…", definición de `[U]` | Sin registro de consultas/cobertura; sin control | `validation/lib/epistemic_label_check.sh` R4, R5 | AU-L5…L8 | control inexistente → 4 de 4 | Comprueba existencia del registro, no su suficiencia; no conectado a ninguna plataforma |
| L4 | `PROTOCOL.md` (contexto), suites | Sin medición de costo | Medición de bytes por sección/adaptador; tiempos por paso en `validation/run_all.sh`; `prompt_bytes`, `prefix_bytes`, `wall_seconds` en `runner.sh` | `run_all.sh` | medido (Resultados §4) | Costo conductual (tokens/llamadas) NO VERIFICABLE sin LLM; verificación adaptativa solo PROPUESTA |
| L5 | §2 etiquetas | Sin reglas de descomposición ni validación de etiquetas | `epistemic_label_check.sh` R1, R2, R3, R6 + fixtures positivos/negativos/fronterizos; tras la revisión: evidencia en blanco no cuenta, `restates` solo de un `[E]` propio con evidencia, transcripción sin afirmaciones = salida 2 | AU-L1…L4, AU-L9, AU-L13…L17 | control inexistente → 10 de 10 | Verifica forma, no corrección; sin concordancia entre anotadores |
| L5 | §2 caducidad de evidencia (v1.5.0) | Solo texto | `epistemic_label_check.sh` R7 | AU-L10, AU-L11 | control inexistente → 2 de 2 | Requiere que el transcript registre acciones y fronteras de sesión |
| L6 | `validation/hooks/pre-commit-secret-scan.sh` | Ruta con espacio → secreto commiteado; checker ausente → `exit 0` | NUL + `--no-renames`; *fail-closed*; blob ilegible = rechazo; `trap '' PIPE` | AU-H1, H2, H3, H7 | H1 0→1, H3 0→1, H7 0→1; H2 0→0 (sin falso positivo) | SIGTERM/SIGKILL; `--no-verify`; hook eliminable |
| L6 | `validation/hooks/pre-commit-spec-immutability.sh` | Ruta con espacio y renombrado → aceptados; **(revisión independiente)** globs expandidos contra el árbol: con dos especificaciones, borrar/renombrar una → aceptado | NUL + `--no-renames`; `set -f`; listado por archivo (fallo de `git diff` = rechazo); `trap '' PIPE` | AU-H4, H5, H6, H9, H10 | H4, H5, H9 0→1; H10 `1(untagged)`→1; H6 →0 (su fallo "antes" es artefacto de H5) | `AGENT_ROLE` autodeclarado; globs sensibles a mayúsculas |
| L6 | `pre-commit-technical-hold.sh`, `pre-commit-phase-branch-gate.sh` | Git for Windows: hook muerto por señal = éxito (demostrado con hook mínimo) | `trap '' PIPE` | AU-H8 | 0→1 | Mismo residual de señales no ignorables |
| L6/L8 | `validation/replay_incident.sh` | Ruta larga → 5 PASS espurios sin repositorio | Preflight (salida 2) + rechazo cuenta solo con etiqueta del control; oráculo G2 exige `REJECTED [spec-immutability` y rechaza "not found" de dash (hallazgo de la revisión) | Ruta larga / corta / hook saboteado | 5 PASS espurios → `ENVIRONMENT ERROR`; 13/13; saboteado → `1(untagged)` | Etiquetas por *grep* de texto: un control que imprima su etiqueta y falle por otra causa no se distingue |
| L7 | `validation/lib/peer_verification_check.sh` | Subcadena: `cat old_impl.py.bak` aceptado como lectura de `impl.py`; `\r` en el registro | Token de ruta; rechazo específico `no_artifact_read`; nota de dependencia de método; limpieza de CR; tras la revisión: comandos que solo nombran el archivo no son lectura, más formas de truncado | AU-P1…P5 + suite original 8/8 | P1, P4, P5 0→1; P3 sin nota → con nota; P2 0→0 | Independencia documental y estadística no modeladas; listas de comandos heurísticas |
| L7/L8 | `validation/peer_verification_suite.sh` | Sin jq: PV7/PV8 PASS vacíos | Preflight jq + oráculo con etiqueta | Ejecución sin jq | 2 PASS espurios → `ENVIRONMENT ERROR` | — |
| L8 | `validation/lib/mutate_check.sh` + suites | Ninguna suite leía `RFP_CHECKER_UNDER_TEST`: todo mutante "sobrevivía" | Suites honran la sustitución con `RFP_CHECKER_TARGET`; línea base sin mutar; operadores fuera de comentarios; operador `exit-var-to-0` | `mutate_check.sh` × 4 checkers | inerte → 11 mutantes eliminados, 0 supervivientes | Solo 4 operadores: cota gruesa |
| L8 | `validation/ab-study/runner.sh`, `preregister.sh` | No compara hashes del preregistro; sin id de modelo; ciego solo de `[E]` cortas | Verificación de hashes (protocolo, tarea, brazo); `AB_MODEL_ID`; `prompt_sha256`; *append-only*; ciego de etiquetas largas, plantilla de corrección y §; `leak-report.txt` | AU-AB1…AB8 | 0 de 8 → 8 de 8 | Fuga residual de vocabulario medida, no eliminada; `sed …/I` es GNU |
| L8/A-B | Nuevo `validation/ab-study/make_arms.sh` | Confusión longitud-contenido reconocida pero sin brazo de control | Brazo placebo de igual longitud en bytes; ablaciones §1, §2, §3, §4–6 | AU-AB9, AB10 | nuevo → 2 de 2 | Bytes ≠ tokens; el placebo no es neutro en todo sentido |
| L8 | README / README.es | DOI "último" = v1.0.0; "Two harnesses" | DOI v1.5.0 y concepto verificados en la API de Zenodo; descripción de las cuatro suites | `sync-check.sh` | en verde | Los pies de los adaptadores siguen llamando "Canonical DOI" al de v1.0.0 (no modificado) |
| L-AS | `validation/lib/anti_sycophancy_check.sh` | Cualquier `TOOL:` previo fundamentaba toda aprobación posterior | Fundamento por turno | AU-S1…S5 | S2 0→1; S1, S3, S4, S5 sin cambio | Cualquier herramienta del turno cuenta; heurístico |

## 2. Reglas: solo instrucción vs. control externo (L6)

"Control externo" = mecanismo ejecutable fuera del modelo, en este repositorio. Ninguno se ejecuta
en producción por defecto: deben instalarse.

| Regla (`PROTOCOL.md`) | Tipo de cumplimiento | Componente | Estado del control |
|---|---|---|---|
| §1 Anti-sycophancy | Solo instrucción + linter heurístico de transcripciones | `anti_sycophancy_check.sh` | Heurístico; no conectado a CI ni a adaptadores |
| §2 Verificar antes de afirmar | Solo instrucción | — | — |
| §2 Cuatro etiquetas | Instrucción + checker estructural (nuevo) | `epistemic_label_check.sh` R1–R6 | Requiere transcripciones estructuradas |
| §2 Caducidad de evidencia | Instrucción + checker (nuevo) | `epistemic_label_check.sh` R7 | Ídem |
| §2 Formato obligatorio de corrección | Solo instrucción | — | — |
| §2 Síntesis de buscador ≠ afirmación resuelta | Solo instrucción (aplicada a citas por `check-claim-support.sh`) | — | Parcial |
| §3 Verificación sobre autoridad | Instrucción | — | — |
| §3.1 Contratos anclados a SHA | Mecanismo (git) disponible; obligatoriedad no controlada | `replay_incident.sh` E1 | Solo demuestra que el mecanismo existe |
| §3.2 Inmutabilidad de especificación | Hook | `pre-commit-spec-immutability.sh` | Endurecido; rol autodeclarado |
| §3.3 Stash por mensaje | Script | `find_stash_by_message.sh` | Funciona si se usa |
| §3.4 Persistencia de auditorías | Solo instrucción | — | — |
| §3.5 Puertas de orden de pipeline | Solo instrucción | — | — |
| §3.6 Un escritor por worktree | Solo instrucción | — | — |
| §3.7 Procedencia de firmas | Solo instrucción | — | — |
| §3.8 Entregable fabricado | Script | `fabricated_deliverable_check.sh` | Funciona si se usa |
| §3.9 Registro de modelo en tiempo de ejecución | Solo instrucción (aplicado al A/B por `runner.sh`) | — | Parcial |
| §3.10 HOLD técnico | Hook | `pre-commit-technical-hold.sh` | Endurecido; rol autodeclarado |
| §3.12 Independencia entre pares | Checker de transcripciones | `peer_verification_check.sh` | Endurecido; no conectado a adaptadores |
| §4.1 Payload vacío → denegar | Aplicado en checkers propios; no hay hook de IDE en el repositorio | checkers (salida 2) | Parcial |
| §4.2 BOM en Windows | Solo instrucción | — | — |
| §4.3–4.4 Controles compensatorios | Solo instrucción | `run_all.sh` aporta registro externo de resultados | Parcial |
| §5 Inmunidad del evaluador | Instrucción; aplicado al A/B (el runner no califica) | `runner.sh` | Parcial |
| §6 Traspaso de sesión | Solo instrucción | — | — |
| (no existe) Contenido recuperado como datos, no instrucciones | Ausente del protocolo | — | **PROPUESTO** como enmienda |
