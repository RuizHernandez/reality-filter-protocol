# Resultados y evidencias — auditoría 2026-10-11

Todo lo que sigue procede de ejecuciones reales en el entorno indicado. Ningún dato es simulado o
estimado salvo donde se dice expresamente (§6). **Ninguna de estas pruebas involucra un LLM**: son
resultados de nivel (B), funcionamiento técnico.

## 1. Entorno

| Elemento | Valor |
|---|---|
| SO | Windows 11 Pro 10.0.26200 (`MINGW64_NT-10.0-26200 3.6.9 x86_64`) |
| Shell | GNU bash 5.3.15 (Git Bash / MSYS2); dash disponible en `/usr/bin/dash` |
| git | 2.55.0.windows.3 |
| jq | 1.7.1, binario oficial `jq-windows-amd64.exe` (985 088 bytes; SHA-256 `7451fbbf…d6ab`, coincide con `sha256sum.txt` del release); descargado con autorización del usuario a la carpeta temporal de la sesión, no instalado en el sistema |
| curl | 8.21.0 |
| Base | `main` @ `9997b900a86ccf2bf01800f9fd92818324a14dce` |
| Rama | `audit/limitaciones-v5` (local, sin push) |

Reproducción completa: `bash validation/run_all.sh /tmp/<dir-corto>` (requiere `jq` en `PATH`; en
Windows, un directorio temporal de ruta corta).

## 2. Línea base (antes de cualquier cambio)

| Comando | Condición | Resultado |
|---|---|---|
| `bash validation/replay_incident.sh <scratchpad largo>` | ruta > 260 caracteres | salida 1; **5 PASS / 8 FAIL**; `git init` falló ("Filename too long") y los 5 PASS eran los 5 rechazos esperados (A2, B1, C1, D1, G1) |
| `bash validation/replay_incident.sh /tmp/rfpB.*` | ruta corta | salida 0; **13/13** |
| `bash validation/peer_verification_suite.sh` | sin `jq` | salida 1; **2 de 8**; PV7 y PV8 "pasan" porque el checker sale con 2 por falta de jq |
| ídem | con `jq` | salida 0; **8/8** |
| `bash validation/skill_gates_suite.sh` | — | salida 0; **13/13** |
| `scripts/sync-check.sh`, `adapter-coverage.sh`, `check-citations.sh`, `check-claims.sh` | — | todos pasan (`check-claims`: 9 anclas no resolubles registradas) |
| `validation/lib/mutate_check.sh` sobre 2 checkers | — | **todos los mutantes "sobreviven"**: herramienta inerte |
| `validation/lib/anti_sycophancy_check.sh` (4 sondas) | — | aprobación tras un `ls` en un turno previo: no marcada (falso negativo) |

### Sondas adversariales previas a la modificación (repositorios desechables en `/tmp`)

| Sonda | Resultado observado |
|---|---|
| Credencial en `my secrets.txt` con el hook de secretos | **commit aceptado** |
| Hook de secretos sin checker | **commit aceptado** |
| Especificación protegida con espacio en la ruta, rol coder | **commit aceptado** |
| Transcript §3.12 con `cat old_impl.py.bak` como verificación de `impl.py` | **salida 0 (aceptado)** |
| Copia ciega del A/B con `[Empirical]` y plantilla de corrección | sin cambios en la copia ciega |
| `runner.sh` | solo comprobaba la existencia de `preregistration.json` |
| Coder renombra la especificación protegida | **commit aceptado** |
| Coder borra la especificación protegida (única) | rechazado |
| Hook mínimo que se mata con SIGPIPE / SIGTERM / `exit 1` | commit **aceptado / aceptado / rechazado** → Git for Windows trata la muerte por señal como éxito |

## 3. Después de los cambios

`bash validation/run_all.sh` (2026-10-11, rama con el árbol de trabajo final, antes de crear este
documento):

| Paso | Salida | Segundos | Resumen |
|---|---|---|---|
| replay | 0 | 8 | PASS=13 FAIL=0 |
| peer | 0 | 6 | PASS=8 FAIL=0 |
| skill-gates | 0 | 4 | PASS=13 FAIL=0 |
| audit | 0 | 35 | PASS=53 FAIL=0 |
| sync-check | 0 | 3 | passed |
| adapter-cov | 0 | 4 | passed |
| citations | 0 | 3 | passed (unresolved: 0) |
| claim-support | 0 | <1 | passed (supported: 4, debt: 2) |
| claims | 1 | 1 | FAILED: `validation/REPORT.md` cita este documento, que aún no existía |

El fallo de `check-claims.sh` es el comportamiento correcto del control (una ruta citada que no
resuelve). La ejecución posterior a la creación de este archivo está en §8.

Registro fechado: `validation/audit_run_2026-10-11.log` (53 PASS).

### Antes/después (OFAT por archivo)

Procedimiento: copia del árbol final; los archivos modificados se sustituyen por su versión de `main`
(`check-claim-support.sh`, inexistente en `main`, queda vacío); se ejecuta la misma
`audit_suite.sh`. Resultado: **26 PASS / 27 FAIL**. Los 27 que fallan con los archivos originales:

| Grupo | Escenarios que fallan "antes" | Causa |
|---|---|---|
| Hooks | AU-H1, H3, H4, H5, H7, H8, H9, H10 | defectos reales de los hooks originales |
| Hooks | AU-H6 | artefacto de secuencia: el renombrado de H5 ya había entrado y no quedaba nada que commitear |
| §3.12 | AU-P1, P3, P4, P5 | subcadena; sin nota de dependencia; comandos que no leen; truncado no reconocido |
| Respaldo documental | AU-C2…C6 | control inexistente |
| Linter | AU-S2 | fundamento no limitado al turno |
| A/B | AU-AB1…AB8 | sin id de modelo, sin hashes, sin *append-only*, ciego parcial, sin `leak-report` |

Los 26 que pasan en ambos estados son controles de no regresión (AU-H2, P2, S1, S3–S5), escenarios
de componentes nuevos sin versión previa (AU-L1–L17; AB9–AB10, que dependen de `make_arms.sh`) y
AU-C1, que pasa trivialmente con el checker vacío. Los escenarios de etiquetas **no tienen
"antes"**: demuestran funcionamiento, no mejora.

## 4. Costo (L4)

| Medida | Valor | Tipo |
|---|---|---|
| `PROTOCOL.md` | 21 981 bytes; 3 080 palabras | medido |
| Por sección (bytes) | §1 1 200; §2 4 398; §3 7 418; §4 1 884; §5 371; §6 801; bibliografía 2 261 | medido |
| Adaptadores (bytes) | Copilot 2 806; Cursor 3 392; Antigravity 4 873; Claude Code 5 414; Kimi 6 141 | medido |
| Tokens del prefijo B | no medido (sin tokenizador del modelo objetivo) | NO VERIFICABLE |
| Suites deterministas | 4–8 s cada una; auditoría 35 s; `run_all` completo ≈ 65 s | medido (una ejecución; sin dispersión) |
| `check-claim-support.sh` | 0,4 s sin red; 4,2 s con `--online` | medido (una ejecución) |
| Costo conductual (tokens, llamadas, latencia del agente) | — | NO VERIFICABLE sin ejecución A/B |

## 5. Verificación de correspondencia documental (L2)

Fuentes releídas el 2026-10-11 (resúmenes primarios): arXiv API para 2603.22582 (v1) y 2608.03421
(v3, actualizada 2026-08-13); página de *Scientific Reports* para doi:10.1038/s41598-026-42705-7
(Crossref no incluye el resumen). Resultado en `scripts/claim-support.tsv`: C1, C3, C4 y C6
SUPPORTED; C2 y C5 PARTIAL (detalle en `TEXTO_CIENTIFICO_REVISADO.md` §3). Crossref
`filter=updates:` sin avisos para Kraidia y Amayuelas; la consulta para el DOI de Wooldridge
(prefijo 10.65109) no devolvió JSON válido: **NO VERIFICABLE**. Zenodo API: 22256185 = v1.5.0
(2026-09-02); 21499994 = v1.0.0; DOI concepto 21499993.

## 6. Cálculo del tamaño muestral (supuestos, no datos)

Fórmula para dos proporciones sin corrección de continuidad, bilateral, potencia 0,80, con
`statistics.NormalDist` de Python 3.12; resultados en `PLAN_EXPERIMENTAL_AB.md` §9. Los valores de
p0 y RR son **supuestos de diseño**.

## 7. Revisión independiente y su resolución

Un subagente revisor de código (contexto separado, sin acceso al razonamiento del auditor, sin
permiso de escritura en el repositorio) revisó el diff y ejecutó sus propias pruebas en una copia en
`/tmp`. **Misma familia de modelos que el auditor: independencia operativa, no estadística.** Cada
hallazgo se reprodujo antes de corregirlo; el informe del revisor no se adoptó como estado.

| # | Hallazgo del revisor | Severidad (revisor) | Reproducido | Resolución | Prueba |
|---|---|---|---|---|---|
| 1 | Hook §3.2: patrones sin entrecomillar expandidos contra el árbol; con dos especificaciones, borrar/renombrar una pasa | Alta | Sí (borrado con P3 presente → salida 0) | `set -f`; listado por archivo | AU-H9, H10 |
| 2 | Checker de etiquetas: `restates` permitía `[E]` sin evidencia (desde `[S]`, de un par, a sí mismo) | Media | Sí (fixtures) | R7 exige `[E]` anterior del mismo agente con evidencia | AU-L13, L14 |
| 3 | R5 solo rechazaba `"universal"` literal; evidencias en blanco contaban; sin afirmaciones → salida 0; `./a` ≠ `a` en R7 | Media | Sí | `absence_scope` debe ser `searched`; `blank`; salida 2; normalización `./` | AU-L15, L16, L17 |
| 4 | Oráculo G2 aceptaba el "not found" de dash; AU-H1 con etiqueta compartida | Media | Por lectura; G2 bajo dash en Linux no ejecutado | G2 exige `REJECTED [spec-immutability`; AU-H1 exige `looks like a credential` | replay 13/13; AU-H1 |
| 5 | Ciego: `  > Correction:`, `**Correction:**` y mayúsculas pasaban; `leak-report` no medía "correction"; JSON sin escapar en preregistro | Baja-media | Sí (agente simulado) | `sed …/gI`; fuga de "correction" medida; validación de comillas | AU-AB7 ampliado |
| 6 | §3.12: `ls`/`echo`/`wc` contaban como lectura; truncados no reconocidos; `\/` innecesario | Baja | Sí | Lista de comandos no lectores; más patrones de truncado | AU-P4, P5 |
| 7 | Pipes que ocultan fallos en hooks; `ver()` de `run_all`; `--online` con versión vacía; "withdrawn" en todo el feed; mutantes poco informativos | Baja | Por lectura | Corregidos los cuatro primeros; la débil cobertura de mutación se declara | — |

El revisor confirmó además, por ejecución, que AU-H7 y AU-H8 sí discriminan frente a los hooks
originales, que los hooks funcionan bajo dash con rutas con espacios, `$`, comillas invertidas y guion
inicial, y que el preregistro y el *append-only* del runner funcionan como se afirma.

**Lección registrada.** El defecto #1 existía en `main`, y la primera pasada de esta auditoría lo dio
por resuelto: la suite de 44 escenarios pasaba sin discriminar ese caso. Es el fallo que el protocolo
describe —aceptar un informe, aquí el propio, como estado— y lo detectó una revisión con contexto
separado.

## 8. Ejecución final

`bash validation/run_all.sh /tmp/rfpF.cDMZ`, 2026-10-11T18:01:02Z, base `9997b90` + árbol de
trabajo de la rama (27 rutas distintas de HEAD, antes del commit): **los 9 pasos con salida 0**.
replay 13/13 (8 s); peer 8/8 (5 s); skill-gates 13/13 (4 s); audit 53/53 (35 s); sync-check,
adapter-coverage, check-citations (0 sin resolver), check-claim-support (4 respaldadas, 2 de deuda)
y check-claims (9 anclas no resolubles registradas) pasan.

## 9. No ejecutado (y por qué)

| Elemento | Motivo |
|---|---|
| Cualquier ejecución con LLM (A/B, ablaciones, T5–T8, dependencia L7) | Requiere autorización de gasto en APIs |
| CI de GitHub con los cambios | Requiere push (no autorizado) |
| Hooks bajo Linux | Sin entorno Linux; dash local solo comprobó sintaxis (el revisor, además, ejecución) |
| Concordancia entre anotadores | Requiere anotadores humanos |
| Respaldo a texto completo de las citas | Solo se leyeron resúmenes |
| Revisión del manuscrito externo | No está en el repositorio |
