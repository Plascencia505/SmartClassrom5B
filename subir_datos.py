import requests
import hashlib
import json

# === CONFIGURACIÓN ===
PROJECT_ID = "smartclassroom-b40d1" # Verifica que este sea tu ID correcto
FIRESTORE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
HEADERS = {"Content-Type": "application/json"}

# === RFID REALES (HEXADECIMAL LIMPIO) ===
RFID_MAESTRO_REAL = "E6 19 CE 05"  # Tarjeta
RFID_ALUMNO_REAL  = "CA 31 48 01"  # Llavero

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest().strip()

# ==========================================
# 1. USUARIOS (6 Docentes + 2 Admins)
# ==========================================
usuarios = {
    # --- MAESTRO REAL ---
    "1042": { 
        "nombre": "Mario López",
        "tipo": "docente",
        "contrasena_hash": hash_password("mario123"),
        "rfid": RFID_MAESTRO_REAL, # <--- RFID REAL AQUÍ
        "horario": [5, 6], 
        "salon_asignado": "MONITOR", # Asignado al hardware real
        "materia": "Sistemas Embebidos",
        "grupos": ["5A"],
        "activo": True
    },
    # --- MAESTROS FALSOS ---
    "1001": { "nombre": "Juan Pérez", "tipo": "docente", "contrasena_hash": hash_password("pass1234"), "rfid": "FAKE0001", "horario": [1, 2], "salon_asignado": "S1", "materia": "Matemáticas", "grupos": ["1A"], "activo": True },
    "1002": { "nombre": "Ana Salas", "tipo": "docente", "contrasena_hash": hash_password("pass1234"), "rfid": "FAKE0002", "horario": [3, 4], "salon_asignado": "S2", "materia": "Historia", "grupos": ["2B"], "activo": True },
    "1003": { "nombre": "Pedro Gil", "tipo": "docente", "contrasena_hash": hash_password("pass1234"), "rfid": "FAKE0003", "horario": [5, 6], "salon_asignado": "S3", "materia": "Química", "grupos": ["3C"], "activo": True },
    "1004": { "nombre": "Luisa M.", "tipo": "docente", "contrasena_hash": hash_password("pass1234"), "rfid": "FAKE0004", "horario": [7, 8], "salon_asignado": "S1", "materia": "Física", "grupos": ["4A"], "activo": True },
    "1005": { "nombre": "Roberto T.", "tipo": "docente", "contrasena_hash": hash_password("pass1234"), "rfid": "FAKE0005", "horario": [9, 10], "salon_asignado": "S2", "materia": "Inglés", "grupos": ["5B"], "activo": True },

    # --- ADMINISTRATIVOS (2) ---
    "2033": {
        "nombre": "Laura Gómez",
        "tipo": "administrativo",
        "contrasena_hash": hash_password("laura123"),
        "rfid": "ADMIN001",
        "jornada": "completa",
        "activo": True
    },
    "2034": {
        "nombre": "Roberto Admin",
        "tipo": "administrativo",
        "contrasena_hash": hash_password("admin123"),
        "rfid": "ADMIN002",
        "jornada": "media",
        "activo": True
    }
}

# ==========================================
# 2. SALONES (1 Real "Monitor" + 3 Falsos)
# ==========================================
salones = {
    # SALÓN REAL (Conectado al Hardware)
    "MONITOR": {
        "nombre": "Laboratorio IoT (Monitor)",
        "edificio": "B",
        "capacidad": 20,
        "maestro_actual": "1042",
        "materia_actual": "Sistemas Embebidos",
        "grupo_actual": "5A",
        "horario": [5, 6],
        "sensores_ref": "monitor", # Apunta a la raíz 'monitor' en Realtime
        "activo": True
    },
    # SALONES FALSOS
    "S1": { "nombre": "Aula 101", "edificio": "A", "capacidad": 40, "maestro_actual": "1001", "materia_actual": "Matemáticas", "grupo_actual": "1A", "horario": [1, 2], "sensores_ref": "salon1", "activo": True },
    "S2": { "nombre": "Aula 102", "edificio": "A", "capacidad": 35, "maestro_actual": "1002", "materia_actual": "Historia", "grupo_actual": "2B", "horario": [3, 4], "sensores_ref": "salon2", "activo": True },
    "S3": { "nombre": "Aula 103", "edificio": "A", "capacidad": 30, "maestro_actual": "1003", "materia_actual": "Química", "grupo_actual": "3C", "horario": [5, 6], "sensores_ref": "salon3", "activo": True }
}

# ==========================================
# 3. ALUMNOS (Gael Real + Relleno)
# ==========================================
alumnos = {
    # --- ALUMNO REAL ---
    "20231245": {
        "nombre": "David Montes",
        "rfid": RFID_ALUMNO_REAL, # <--- RFID REAL AQUÍ
        "grupo": "5A",
        "materias": {
            # Apunta al salón MONITOR para que funcione la demo
            "Sistemas Embebidos": {"horario": [5, 6], "maestro": "1042", "salon": "MONITOR"} 
        },
        "activo": True
    },
    # --- ALUMNOS RELLENO ---
    "20239901": { "nombre": "Ana Torres", "rfid": "FAKEALU1", "grupo": "5A", "materias": { "Sistemas Embebidos": {"horario": [5, 6], "maestro": "1042", "salon": "MONITOR"} }, "activo": True },
    "20239902": { "nombre": "Luis Herrera", "rfid": "FAKEALU2", "grupo": "5A", "materias": { "Sistemas Embebidos": {"horario": [5, 6], "maestro": "1042", "salon": "MONITOR"} }, "activo": True },
    "20239903": { "nombre": "Sofía Méndez", "rfid": "FAKEALU3", "grupo": "5A", "materias": { "Sistemas Embebidos": {"horario": [5, 6], "maestro": "1042", "salon": "MONITOR"} }, "activo": True }
}

# === FUNCIONES DE SUBIDA (NO TOCAR) ===
def convertir_a_firestore_formato(diccionario):
    def formato_valor(v):
        if isinstance(v, str): return {"stringValue": v}
        elif isinstance(v, bool): return {"booleanValue": v}
        elif isinstance(v, int): return {"integerValue": str(v)}
        elif isinstance(v, float): return {"doubleValue": v}
        elif isinstance(v, list): return {"arrayValue": {"values": [formato_valor(x) for x in v]}}
        elif isinstance(v, dict): return {"mapValue": {"fields": {k: formato_valor(val) for k, val in v.items()}}}
        else: return {"nullValue": None}
    return {"fields": {k: formato_valor(v) for k, v in diccionario.items()}}

def subir_coleccion(nombre_coleccion, datos):
    print(f"\n--- Subiendo {nombre_coleccion} ---")
    for doc_id, contenido in datos.items():
        # CORRECCIÓN: La URL apunta directo al recurso para PATCH
        url = f"{FIRESTORE_URL}/{nombre_coleccion}/{doc_id}"
        
        body = convertir_a_firestore_formato(contenido)
        
        # Usamos PATCH. Si el documento no existe, lo crea. Si existe, lo actualiza.
        res = requests.patch(url, headers=HEADERS, data=json.dumps(body)) 
        
        if res.status_code == 200:
            print(f"✅ {doc_id} OK")
        else:
            print(f"❌ Error {doc_id}: {res.text}")

# EJECUTAR
if __name__ == "__main__":
    subir_coleccion("usuarios", usuarios)
    subir_coleccion("salones", salones)
    subir_coleccion("alumnos", alumnos)