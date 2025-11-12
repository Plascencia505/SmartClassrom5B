import requests
import hashlib
import json

# === CONFIGURACIÓN GENERAL ===
PROJECT_ID = "smartclassroom-b40d1"
FIRESTORE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
HEADERS = {"Content-Type": "application/json"}

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest().strip()

# === DATOS ===
usuarios = {
    "1042": {
        "nombre": "Mario López",
        "tipo": "docente",
        "contrasena_hash": hash_password("mario123"),
        "rfid": "A1B2C3D4",
        "horario": [5, 6],
        "salon_asignado": "S101",
        "materia": "Sistemas Embebidos",
        "grupos": ["5A", "7A"],
        "activo": True
    },
    "1077": {
        "nombre": "Paola García",
        "tipo": "docente",
        "contrasena_hash": hash_password("paola123"),
        "rfid": "B2C3D4E5",
        "horario": [1, 2],
        "salon_asignado": "S203",
        "materia": "Bases de Datos",
        "grupos": ["3A"],
        "activo": True
    },
    "1030": {
        "nombre": "Carlos Ramírez",
        "tipo": "docente",
        "contrasena_hash": hash_password("carlos123"),
        "rfid": "C3D4E5F6",
        "horario": [7, 8],
        "salon_asignado": "S204",
        "materia": "Redes",
        "grupos": ["7A"],
        "activo": True
    },
    "2033": {
        "nombre": "Laura Gómez",
        "tipo": "administrativo",
        "contrasena_hash": hash_password("laura123"),
        "rfid": "E5F6G7H8",
        "jornada": "completa",
        "horario_descanso": {
            "almuerzo": [13, 14],
            "comida": [16, 17]
        },
        "activo": True
    }
}

alumnos = {
    "20231245": {
        "nombre": "Gael Plascencia",
        "rfid": "93A4B12F",
        "grupo": "5A",
        "materias": {
            "Sistemas Embebidos": {"horario": [5, 6], "maestro": "1042", "salon": "S101"},
            "Redes": {"horario": [7, 8], "maestro": "1030", "salon": "S204"}
        },
        "activo": True
    },
    "20239876": {
        "nombre": "Ana Torres",
        "rfid": "B78C92D4",
        "grupo": "5A",
        "materias": {
            "Sistemas Embebidos": {"horario": [5, 6], "maestro": "1042", "salon": "S101"}
        },
        "activo": True
    },
    "20231246": {
        "nombre": "Luis Herrera",
        "rfid": "D45E67F8",
        "grupo": "3A",
        "materias": {
            "Bases de Datos": {"horario": [1, 2], "maestro": "1077", "salon": "S203"}
        },
        "activo": True
    },
    "20234567": {
        "nombre": "Sofía Méndez",
        "rfid": "E98F12C3",
        "grupo": "7A",
        "materias": {
            "Redes": {"horario": [7, 8], "maestro": "1030", "salon": "S204"}
        },
        "activo": True
    },
    "20236789": {
        "nombre": "Miguel Lara",
        "rfid": "F23A56B7",
        "grupo": "7A",
        "materias": {
            "Redes": {"horario": [7, 8], "maestro": "1030", "salon": "S204"}
        },
        "activo": True
    }
}

salones = {
    "S101": {
        "nombre": "Salón 101",
        "edificio": "B",
        "capacidad": 40,
        "maestro_actual": "1042",
        "materia_actual": "Sistemas Embebidos",
        "grupo_actual": "5A",
        "horario": [5, 6],
        "sensores_ref": "/salones/salon_01",
        "activo": True
    },
    "S203": {
        "nombre": "Salón 203",
        "edificio": "C",
        "capacidad": 35,
        "maestro_actual": "1077",
        "materia_actual": "Bases de Datos",
        "grupo_actual": "3A",
        "horario": [1, 2],
        "sensores_ref": "/salones/salon_02",
        "activo": True
    },
    "S204": {
        "nombre": "Salón 204",
        "edificio": "C",
        "capacidad": 35,
        "maestro_actual": "1030",
        "materia_actual": "Redes",
        "grupo_actual": "7A",
        "horario": [7, 8],
        "sensores_ref": "/salones/salon_03",
        "activo": True
    }
}


def convertir_a_firestore_formato(diccionario):
    """Convierte un dict normal a formato Firestore REST API."""
    def formato_valor(v):
        if isinstance(v, str):
            return {"stringValue": v}
        elif isinstance(v, bool):
            return {"booleanValue": v}
        elif isinstance(v, int):
            return {"integerValue": str(v)}
        elif isinstance(v, float):
            return {"doubleValue": v}
        elif isinstance(v, list):
            return {"arrayValue": {"values": [formato_valor(x) for x in v]}}
        elif isinstance(v, dict):
            return {"mapValue": {"fields": {k: formato_valor(val) for k, val in v.items()}}}
        else:
            return {"nullValue": None}

    return {"fields": {k: formato_valor(v) for k, v in diccionario.items()}}


def subir_coleccion(nombre_coleccion, datos):
    for doc_id, contenido in datos.items():
        url = f"{FIRESTORE_URL}/{nombre_coleccion}?documentId={doc_id}"
        body = convertir_a_firestore_formato(contenido)
        res = requests.post(url, headers=HEADERS, data=json.dumps(body))
        if res.status_code == 200:
            print(f"✅ Documento {doc_id} subido a /{nombre_coleccion}")
        else:
            print(f"❌ Error con {doc_id}: {res.text}")


# Subir las colecciones
subir_coleccion("usuarios", usuarios)
subir_coleccion("alumnos", alumnos)
subir_coleccion("salones", salones)
