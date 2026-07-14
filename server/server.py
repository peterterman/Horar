from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, UploadFile, File, Form, Request
from fastapi.responses import JSONResponse
from openai import OpenAI
import base64
import os
import json

app = FastAPI()


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://toft-terman.dk",
        "https://www.toft-terman.dk",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

@app.get("/")
def home():
    return {
        "status": "ok",
        "service": "spisetavle-horar-ai",
        "endpoints": [
            "/analyze-image",
            "/horar-answer",
            "/horar-house-suggestion"
        ]
    }

@app.post("/analyze-image")
async def analyze_image(device_id: str = Form(...), image: UploadFile = File(...)):
    """Eksisterende SpiseTavle-endpoint."""
    try:
        content = await image.read()
        image_base64 = base64.b64encode(content).decode("utf-8")

        mime = image.content_type
        if mime is None or mime == "application/octet-stream":
            filename = (image.filename or "").lower()
            if filename.endswith(".png"):
                mime = "image/png"
            elif filename.endswith(".webp"):
                mime = "image/webp"
            else:
                mime = "image/jpeg"

        data_url = f"data:{mime};base64,{image_base64}"

        response = client.responses.create(
            model="gpt-4.1-mini",
            input=[{
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": "Analyser billedet af måltidet. Returner kun rå JSON uden markdown i formatet: {\"foods\":[{\"name\":\"fødevare\",\"grams\":100}],\"confidence\":\"low|medium|high\",\"note\":\"kort bemærkning\"}. Brug danske fødevarenavne. Estimer gram realistisk."
                    },
                    {
                        "type": "input_image",
                        "image_url": data_url
                    }
                ]
            }]
        )

        text = response.output_text.strip()

        if text.startswith("```"):
            text = text.replace("```json", "").replace("```", "").strip()

        try:
            result = json.loads(text)
        except Exception:
            result = {"foods": [], "confidence": "low", "note": text}

        return JSONResponse(result)

    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)


@app.post("/horar-answer")
async def horar_answer(request: Request):
    """Nyt Horar-endpoint.

    Flutter-appen sender IKKE OpenAI-nøgle. Den sender kun:
    - brugerens spørgsmål
    - appens beregnede horariske resultat
    - score/sandsynlighedsindikation
    - vigtigste astrologiske faktorer

    Serveren formulerer derefter et kort kontekstsvar på dansk.
    """
    try:
        payload = await request.json()

        prompt = _build_horar_prompt(payload)

        response = client.responses.create(
            model="gpt-4.1-mini",
            input=[{
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": prompt
                    }
                ]
            }]
        )

        text = response.output_text.strip()

        if text.startswith("```"):
            text = text.replace("```json", "").replace("```", "").strip()

        try:
            result = json.loads(text)
            answer = str(result.get("answer", "")).strip()
            if not answer:
                answer = text
        except Exception:
            answer = text

        return JSONResponse({
            "answer": answer
        })

    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)


@app.post("/horar-house-suggestion")
async def horar_house_suggestion(request: Request):
    """Foreslå horarisk hus før selve horar-beregningen.

    Appen sender kun spørgsmålet og de lokale regelbaserede forslag.
    Serveren returnerer et struktureret forslag, som appen kan bruge som
    startpunkt. Selve horar-beregningen sker stadig lokalt i appen.
    """
    try:
        payload = await request.json()
        prompt = _build_house_suggestion_prompt(payload)

        response = client.responses.create(
            model="gpt-4.1-mini",
            input=[{
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": prompt
                    }
                ]
            }]
        )

        text = response.output_text.strip()
        if text.startswith("```"):
            text = text.replace("```json", "").replace("```", "").strip()

        try:
            result = json.loads(text)
        except Exception:
            result = {
                "house": None,
                "question_type": "general",
                "confidence": "low",
                "reason": text,
                "derived_house_explanation": None,
            }

        house = result.get("house")
        try:
            house = int(house)
        except Exception:
            house = None

        if house is None or house < 1 or house > 12:
            return JSONResponse({
                "status": "error",
                "message": "AI returnerede ikke et gyldigt hus.",
                "raw": result,
            }, status_code=422)

        return JSONResponse({
            "house": house,
            "question_type": str(result.get("question_type") or "general"),
            "confidence": str(result.get("confidence") or "medium"),
            "reason": str(result.get("reason") or "AI foreslår dette hus ud fra spørgsmålets formulering."),
            "derived_house_explanation": result.get("derived_house_explanation"),
        })

    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)


def _build_horar_prompt(payload: dict) -> str:
    question = payload.get("question", "")
    answer_mode = payload.get("answer_mode", "")
    question_type = payload.get("question_type", "")
    house = payload.get("quesited_house", "")
    result = payload.get("calculated_result", {}) or {}
    significators = payload.get("significators", {}) or {}
    aspects = payload.get("main_aspects", {}) or {}
    factors = payload.get("top_weighted_factors", []) or []
    special = payload.get("special_reading", None)
    notes = payload.get("notes", []) or []

    compact_payload = {
        "question": question,
        "answer_mode": answer_mode,
        "question_type": question_type,
        "quesited_house": house,
        "calculated_result": result,
        "significators": significators,
        "main_aspects": aspects,
        "top_weighted_factors": factors[:6],
        "special_reading": special,
        "notes": notes[:10],
    }

    return (
        "Du skal formulere et kort, brugbart svar til brugeren på dansk ud fra "
        "en horarisk beregning, som allerede er udført af appen.\n\n"

        "Vigtige regler:\n"
        "- Du må ikke selv opfinde nye astrologiske beregninger.\n"
        "- Brug kun oplysningerne i JSON-data.\n"
        "- Svar i samme form som spørgsmålet: ja/nej, hvor, hvornår, hvem, hvor meget, hvordan, hvorfor eller hvad.\n"
        "- Hvis spørgsmålet er 'hvor', må du ikke svare som ja/nej. Brug i stedet sted-, hus- og tegn-hints.\n"
        "- Hvis spørgsmålet er 'hvornår', må du ikke svare som ja/nej. Brug timing, aspekt og usikkerhed.\n"
        "- Hvis spørgsmålet er 'hvem', må du ikke svare som ja/nej. Beskriv mulig aktør/personrolle.\n"
        "- Hvis spørgsmålet er 'hvor meget', må du ikke svare som ja/nej. Beskriv omfang/styrke/retning.\n"
        "- Nævn sandsynlighed/styrke kun som astrologisk indikation, ikke som objektiv statistik.\n"
        "- Nævn højst 3-4 vigtigste grunde.\n"
        "- Skriv klart og kort, cirka 6-10 linjer.\n"
        "- Ved helbred, jura eller økonomi: tilføj at svaret ikke erstatter professionel rådgivning.\n"
        "- Skriv ikke markdown-tabeller.\n\n"

        "Returner kun rå JSON uden markdown i dette format:\n"
        "{\"answer\":\"dit danske svar her\"}\n\n"

        "DATA:\n"
        f"{json.dumps(compact_payload, ensure_ascii=False, indent=2)}"
    )



def _build_house_suggestion_prompt(payload: dict) -> str:
    question = str(payload.get("question", "")).strip()
    local_suggestions = payload.get("local_suggestions", []) or []
    allowed_types = payload.get("allowed_question_types", []) or []

    compact_payload = {
        "question": question,
        "local_suggestions": local_suggestions[:5],
        "allowed_question_types": allowed_types,
    }

    return (
        "Du er en klassisk horarisk assistent. Du skal KUN foreslå hvilket hus "
        "spørgsmålet bør behandles fra, før selve horarberegningen. Du må ikke "
        "tolke kortet, give svar på spørgsmålet eller beregne planeter.\n\n"

        "Brug klassiske horariske husregler og afledte huse. Vigtige regler:\n"
        "- Spørgeren selv: 1. hus.\n"
        "- Egen ejendel, penge eller tabt ting: 2. hus.\n"
        "- Partner/ægtefælle/modpart/åben modstander: 7. hus.\n"
        "- Partnerens ejendel/penge/tabte ting: 2. fra 7. = 8. hus.\n"
        "- Barn: 5. hus. Barnets partner: 7. fra 5. = 11. hus. Barnets partners job: 10. fra 11. = 8. hus.\n"
        "- Job, karriere, chef, titel, offentlig sejr, mesterskab, pokal, verdensmester: 10. hus.\n"
        "- Sport/spil kan være 5. hus som emnebaggrund, men 'hvem vinder VM/turneringen/titlen' bruger 10. hus som hovedhus.\n"
        "- Konkret duel med to parter: 1./7. hus for parterne; 10. hus kan være bekræftende titel/sejrsfaktor.\n"
        "- Hvor-spørgsmål om en ting skal stadig vælge tingens hus, ikke blot spørgeordet.\n"
        "- Hvis relation + genstand findes, brug afledt hus. Eksempel: 'Hvor er min kones tørklæde?' = kone 7. hus, tørklæde som hendes ejendel = 2. fra 7. = 8. hus.\n"
        "- Hvis du er usikker, vælg det mest praktisk anvendelige hus og giv kort forbehold.\n\n"

        "Returner kun rå JSON uden markdown i dette format:\n"
        "{\"house\":8,\"question_type\":\"partnerMoney\",\"confidence\":\"high|medium|low\",\"reason\":\"kort dansk forklaring\",\"derived_house_explanation\":\"kort forklaring eller null\"}\n\n"
        "question_type skal være et af navnene i allowed_question_types. Hvis intet passer, brug general.\n\n"
        "DATA:\n"
        f"{json.dumps(compact_payload, ensure_ascii=False, indent=2)}"
    )
