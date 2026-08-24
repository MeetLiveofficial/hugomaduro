# -*- coding: utf-8 -*-
"""Generate LKey catalog, app fallbacks, and fill missing CSV / admin JSON keys."""
from __future__ import annotations

import csv
import json
import re
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from i18n_extra_langs import AR_MISSING, RU_MISSING, UK_MISSING, ZH_MISSING

APP = Path(r"C:\laragon\www\nexus_krimson\nexus_rs_app")
BACKEND = Path(r"C:\laragon\www\nexus_krimson\nexus_rs")
KEYS_FILE = APP / "lib" / "languages" / "languages_keys.dart"
LIB_LANG = APP / "lib" / "languages"
CSV_DIR = BACKEND / "database" / "seeders" / "data"
ES_JSON = BACKEND / "resources" / "lang" / "es.json"
EN_JSON = BACKEND / "resources" / "lang" / "en.json"
VIEWS = BACKEND / "resources" / "views"


def parse_lkeys(src: str) -> dict[str, str]:
    """Parse `static const String name = "..." [ "..." ];` including concatenations."""
    keys: dict[str, str] = {}
    # Remove line comments except inside strings is hard; strip // comments outside strings
    pattern = re.compile(
        r"static const String (\w+)\s*=\s*((?:\"(?:\\.|[^\"\\])*\"\s*)+);",
        re.S,
    )

    def unescape(s: str) -> str:
        return (
            s.replace("\\\\", "\0")
            .replace("\\n", "\n")
            .replace("\\t", "\t")
            .replace('\\"', '"')
            .replace("\\'", "'")
            .replace("\\$", "$")
            .replace("\0", "\\")
        )

    for m in pattern.finditer(src):
        name = m.group(1)
        parts = re.findall(r"\"((?:\\.|[^\"\\])*)\"", m.group(2))
        keys[name] = unescape("".join(parts))
    return keys


def load_csv(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.exists():
        return out
    with path.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f)
        next(reader, None)
        for row in reader:
            if len(row) >= 2 and row[0]:
                out[row[0]] = row[1]
    return out


def norm(s: str) -> str:
    return re.sub(r"[\s\n\r]+", "", s)


def match_csv(lkey_val: str, csv_map: dict[str, str]) -> str | None:
    if lkey_val in csv_map:
        return csv_map[lkey_val]
    n = norm(lkey_val)
    for k, v in csv_map.items():
        if norm(k) == n:
            return v
    return None


def dart_escape(s: str) -> str:
    return (
        s.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", "\\n")
        .replace("\r", "")
    )


def looks_spanish_admin(s: str) -> bool:
    if re.search(r"[áéíóúñÁÉÍÓÚÑ¿¡]", s):
        return True
    return bool(
        re.search(
            r"\b(de|del|la|el|los|las|para|por|con|que|un|una|al|se|tu|días|nivel|saldo|monedero|llamada)\b",
            s.lower(),
        )
    )


def looks_spanish(s: str) -> bool:
    if re.search(r"[áéíóúñÁÉÍÓÚÑ¿¡]", s):
        return True
    words = {
        "de",
        "para",
        "tu",
        "tus",
        "el",
        "la",
        "los",
        "las",
        "un",
        "una",
        "con",
        "por",
        "que",
        "del",
        "precio",
        "llamada",
        "soporte",
        "ticket",
        "nivel",
        "monedas",
        "llamadas",
        "actividad",
        "calidad",
        "confirmar",
        "editar",
        "necesitas",
        "conexión",
        "guest",
    }
    toks = set(re.findall(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]+", s.lower()))
    return len(toks & words) >= 2


# English for LKeys whose constant value is already Spanish.
EN_FOR_SPANISH_KEYS: dict[str, str] = {
    "supportChat": "Support Chat",
    "supportChatSubtitle": "Create a support ticket",
    "supportChatHint": "Describe your issue…",
    "supportChatEmpty": "Write your first message to open a ticket.",
    "supportBadge": "SUPPORT",
    "editCalls": "Edit Calls",
    "callPriceScreenTitle": "Call price",
    "myPrivateCallPrice": "My private call price",
    "myCurrentGrade": "My current level",
    "callPriceTipsTitle": "Call price tip",
    "callPriceLockedHint": "Only ranks A and S can edit the price. Everyone else sees the platform fixed amount.",
    "confirm": "Confirm",
    "weeklyLevel": "Level",
    "streamerAverageNeed": "You need @n points to reach @grade",
    "avgCoins": "Coins",
    "avgCalls": "Calls",
    "avgLive": "Connection",
    "avgActivity": "Activity",
    "avgQuality": "Quality",
    "freeMatchesUsed": "You already used your 2 free Matches today! Top up coins and keep the fun going.",
}

# Spanish for English LKey values missing from es.csv (and quality upgrades).
ES_MISSING: dict[str, str] = {
    "language": "Idioma",
    "all": "Todos",
    "feed": "Feed",
    "following": "Siguiendo",
    "post": "PUBLICAR",
    "nearby": "Cerca",
    "next": "Siguiente",
    "agreeToPolicy": "Al continuar, aceptas la",
    "continueAsGuest": "Continuar como invitado",
    "joinToContinue": "Vincular cuenta",
    "joinToContinueDescription": "Puedes seguir usando la app como Guest. Vincula un email si quieres recuperar esta cuenta más adelante.",
    "joinNow": "Vincular ahora",
    "guestAccountExpires": "Las cuentas Guest no caducan. Tienen los mismos privilegios que un cliente.",
    "clientsRanking": "Ranking de clientes",
    "streamersRanking": "Ranking de streamers",
    "callStreamerInCall": "Esta streamer está en una llamada",
    "callStreamerOffline": "Esta streamer está desconectada",
    "onlineNow": "En línea",
    "callOnlyFromLive": "Entra al LIVE para llamarla",
    "joinThisLive": "Unirse al LIVE",
    "callEndedInsufficientCoins": "No tienes coins suficientes para continuar la llamada",
    "callEndedClientNoCoins": "La llamada terminó: el cliente no tiene coins",
    "liveBadge": "En vivo",
    "peopleWatching": "@count personas viendo",
    "lastCallMinutesAgo": "ÚLTIMA LLAMADA HACE @min MIN",
    "lastCallHoursAgo": "ÚLTIMA LLAMADA HACE @hours H",
    "impression": "Impresión",
    "rankLabel": "Rango: @grade",
    "rateImpression": "Calificar",
    "herTraits": "Así se define",
    "otherTraits": "Más cualidades",
    "maxTraitsHint": "Elige hasta @count",
    "ratingSaved": "Gracias por calificar",
    "offlineBadge": "Fuera de línea",
    "calling": "Llamando…",
    "ringing": "Sonando…",
    "connecting": "Conectando…",
    "receiveMatch": "Recibir Match",
    "receiveMatchHint": "Permitir que los clientes hagan Match contigo",
    "networkWifi": "Wi‑Fi",
    "blockUserConfirmation": "¿Seguro que quieres bloquear a este usuario? Ya no verás su contenido ni podrá interactuar contigo.",
    "deleteAccountMessage": "¿De verdad quieres eliminar tu cuenta? Se borrarán todos tus datos y no podrás recuperarlos.",
    "sessionExpiredTitle": "Sesión expirada – Iniciaste sesión en otro dispositivo",
    "sessionExpiredMessage": "Por seguridad, @app_name permite solo una sesión activa por cuenta. Se cerró esta sesión porque tu cuenta se usó en otro dispositivo.",
    "freezeDescription": "Lo sentimos, tu cuenta está temporalmente congelada. Puede deberse a reportes o a una revisión de seguridad. Contáctanos si crees que es un error.",
    "textRejectedAndContainsSuchThings": "El texto se rechazó porque incluye: ",
    "mediaRejectedAndContainsSuchThings": "El contenido se rechazó porque incluye: ",
    "stopBattleDescription": "¿Seguro que quieres detener la batalla? Esta acción no se puede deshacer.",
    "invitedListEmptyDescription": "Aún no has invitado a nadie. Aquí aparecerán los usuarios invitados.",
    "noUserReelsDescription": "Este usuario aún no ha publicado reels.",
    "noMyPostsTitle": "Aún no has compartido publicaciones",
    "noUserPostsDescription": "Este usuario aún no ha compartido publicaciones.",
    "cannotLeaveDuringBattle": "No puedes salir del LIVE mientras hay una batalla en curso.",
    "exitLiveStreamDescription": "¿Seguro que quieres salir del LIVE?\nSi el stream terminó, no podrás volver a entrar.",
    "qrCodeMessage": "artista. Me inspiro en la naturaleza y la vida urbana. Conversemos.",
    "postCommentEmptyDescription": "Esta publicación no tiene comentarios. Únete y comparte tu opinión.",
    "blockListEmptyDescription": "Los usuarios que bloquees aparecerán aquí. Aún no has bloqueado a nadie.",
    "registrationBonusTitle": "¡Bono de bienvenida acreditado en tu monedero!",
    "tasksEndToday": "Las tareas de hoy terminan en",
    "liveMinutesLabel": "Tiempo LIVE",
    "goDoTask": "Ir",
    "goToLiveCategory": "Ir a LIVE",
    "goToMatchCategory": "Ir a Match",
    "goToChatCategory": "Ir a Chat",
    "goToProfileCategory": "Ir a Perfil",
    "goToExploreCategory": "Ir a Explorar",
    "goToFeedCategory": "Crear publicación",
    "nextTaskUnlocked": "Siguiente tarea desbloqueada",
    "completeFirstTaskToContinue": "Completa la Tarea 1 para ir a esta categoría",
    "streamerAverage": "Promedio",
    "streamerAverageNeedOne": "Necesitas 1 punto para llegar a @grade",
    "balance": "Saldo",
    "collected": "Acumulado*",
    "gifted": "Regalado*",
    "purchased": "Comprado*",
    "taskCategoryLive": "LIVE",
    "taskCategoryOther": "Otras",
    "tasksOnlyForStreamers": "Las tareas solo están disponibles para streamers.",
    "withdrawalPointsProgress": "Puntos para retiro @current / @target pts",
    "liveAndOtherPoints": "LIVE: @live/@liveMax · Otras: @other/@otherMax",
    "todayLiveOtherGoal": "Hoy LIVE @live + Otras @other (meta @target)",
    "tasksWorkHint": "LIVE 120 pts + Otras 30 pts = 150 para retiro. Grado B/C: tareas de llamadas privadas.",
    "callPriceTip1": "El precio de llamada lo ajusta la plataforma según tu rendimiento.",
    "callPriceTip2": "Para cambiar el rango de precio, contacta a soporte o a tu agente.",
    "callPriceTip3": "Subir el precio puede aumentar tus ingresos, pero no lo hagas de golpe.",
    "callPriceTip4": "Si al subir el precio bajan las llamadas, restaura el precio anterior.",
    "callPriceTip5": "Prueba varios montos hasta equilibrar volumen de llamadas e ingresos.",
    "callPriceTipRangeHint": "Rango A: precio dentro del límite A. Rango S: límite más amplio.",
    "searchUsersEllipsis": "Buscar usuarios…",
    "durationMinutesAbbr": "@count min",
    "durationSecondsAbbr": "@count s",
    "durationMinSec": "@m min @s s",
    "minutesUnit": "min",
    "activeFilter": "Activos",
    "clearFilters": "Limpiar",
    "clientsOnlyMessages": "Con clientes solo puedes enviar mensajes",
    "streamerNotReceivingCalls": "Esta streamer no recibe llamadas ahora",
    "liveNotAvailable": "El LIVE no está disponible",
    "enterMatchToWaitClients": "Entra a Match para abrir tu cámara y esperar clientes",
    "liveTask1": "Tarea LIVE 1",
    "liveTask2": "Tarea LIVE 2",
    "liveTask3": "Tarea LIVE 3",
    "liveTask4": "Tarea LIVE 4",
    "liveMaxTask": "Tarea LIVE Máx",
    "liveTask1Desc": "60 min LIVE + meta de coins 1",
    "liveTask2Desc": "90 min LIVE + meta de coins 2",
    "liveTask3Desc": "120 min LIVE + meta de coins 3",
    "liveTask4Desc": "240 min LIVE + meta de coins 4",
    "liveMaxTaskDesc": "150 min LIVE + meta máxima de coins (completa las anteriores)",
    "liveTasksCategory": "Tareas LIVE",
    "otherActivitiesCategory": "Otras actividades",
    "privateCallTasksBc": "Tareas de llamada privada B/C",
    "interactionsTask": "Interacciones",
    "interactionsTaskDesc": "Completa 10 interacciones (mensajes, likes, respuestas)",
    "privateCall5MinTask": "Llamada privada 5 min",
    "privateCall5MinTaskDesc": "Completa 1 llamada privada de al menos 5 minutos facturables",
    "dailyActivityTask": "Actividad diaria",
    "dailyActivityTaskDesc": "Publica una publicación o actualiza tu perfil hoy",
    "taskT01": "T01 — 5 llamadas de 5 min",
    "taskT01Desc": "Completa 5 llamadas facturables distintas de al menos 5 minutos",
    "taskT02": "T02 — 10 Matches",
    "taskT02Desc": "Completa 10 Matches (20 segundos gratis completos)",
    "taskT03": "T03 — Regalos en 5 llamadas",
    "taskT03Desc": "Recibe al menos 1 regalo en 5 llamadas distintas",
    "taskT04": "T04 — Publicar historia",
    "taskT04Desc": "Publica 1 historia válida",
    "taskT05": "T05 — Responder 10 mensajes",
    "taskT05Desc": "Responde 10 mensajes recibidos distintos",
    "taskT06": "T06 — Llamada de 20 min",
    "taskT06Desc": "Completa 1 llamada facturable de al menos 20 minutos",
    "taskT07": "T07 — Coins de regalos",
    "taskT07Desc": "Acumula coins de regalos",
    "taskT08": "T08 — 6 h en línea",
    "taskT08Desc": "Acumula 6 horas de conexión válida",
    "callCostPerMin": "@coins/min",
    "callGoalNotMet": "Meta de llamadas no cumplida",
    "callGoalMet": "Meta de llamadas cumplida",
    "detail": "Detalle",
    "todaysCalls": "Llamadas de hoy",
    "diamonds": "Diamantes",
    "gems": "Gemas",
    "onlineTime": "Tiempo en línea",
    "avgCallDuration": "Duración promedio",
    "positiveRating": "Valoración positiva",
    "todaysEarnings": "Ganancias de hoy",
    "earningsFromCalls": "Ganancias por llamadas",
    "earningsFromGifts": "Ganancias por regalos",
    "earningsFromTasks": "Ganancias por tareas",
    "earningsFromInvites": "Ganancias por invitaciones",
    "managedEarnings": "Ganancias gestionadas",
    "rejections": "Rechazos",
    "rejectionRate": "Tasa de rechazo",
    "weeklyLevelPrivateLiveOnly": "Nivel semanal (solo privado y LIVE)",
    "category": "Categoría",
    "thisWeek": "Esta semana",
    "lastWeek": "La semana pasada",
    "levelResponseRate": "Tasa de respuesta del nivel",
    "levelAvgDuration": "Duración promedio del nivel",
    "levelCalls": "Llamadas del nivel",
    "levelUpdateTime": "Actualización de nivel",
    "currentLevelBenefits": "Beneficios del nivel actual",
    "connected": "Conectada",
    "disconnected": "Desconectada",
    "withdraw": "Retirar",
    "waitingBattleResponse": "Esperando respuesta a la batalla…",
    "waitingForUser": "Esperando a @name…",
    "walletHistory": "Historial de monedero",
    "walletIncome": "ingresos",
    "walletWithdrawLabel": "retiros",
    "walletGiftFrom": "Regalo de @name",
    "walletGiftLiveFrom": "Regalo en LIVE de @name",
    "walletGiftChatFrom": "Regalo en chat de @name",
    "walletGiftCallFrom": "Regalo en llamada de @name",
    "walletPrivateCallWith": "Llamada privada con @name",
    "walletMatchWith": "Match con @name",
    "walletNoHistory": "Sin movimientos",
    "walletNoHistoryDesc": "Aquí verás las monedas de LIVE, chat, llamadas y otros regalos.",
    "walletFilterAll": "Todo el historial",
    "walletFilterLive": "De LIVE",
    "walletFilterChat": "De chat",
    "walletFilterCalls": "De llamadas",
    "walletFilterGifts": "Otros regalos",
    "walletRechargeItem": "Recarga de monedas",
    "walletWithdrawItem": "Retiro",
    "walletExchangeRate": "Tasa de cambio: @coins Coins = @currency1",
    "newFollowers": "Nuevos seguidores",
    "walletAgencyShareFrom": "Comisión de @name",
    "agencyDashboardTitle": "Agencia",
    "agencyYourStreamers": "Tus streamers afiliados",
    "agencyNoStreamers": "Aún no tienes streamers",
    "agencyCreateStreamerHint": "Crea una cuenta Streamer afiliada a tu agencia.",
    "agencyCreateStreamer": "Crear streamer",
    "agencyStreamerEarned": "Ganó el streamer",
    "agencyYourShare": "Tu comisión",
    "agencyMonth": "Este mes",
    "agencyLifetime": "Total",
    "agencyWalletHint": "10% del margen App de tus streamers",
    "vipBadge": "VIP",
    "saveRating": "Guardar",
    "rating": "Calificación",
    "addMore": "Añadir más",
    "locationError": "Error de ubicación",
    "kycCheckStatus": "Ya terminé — verificar estado",
    "retry": "Reintentar",
    "enableCamera": "Activar cámara",
    "withdrawMethod": "Método de retiro",
    "payoutAccount": "Cuenta / wallet de cobro",
    "battleEndedTitle": "Batalla terminada",
    "noLeave": "No, salir",
    "yesAnotherPk": "Sí, otra PK",
    "notNow": "Ahora no",
    "payCardPseNequi": "Tarjeta / Nequi / QR",
    "payWompi": "Wompi · Colombia e Internacional",
    "cryptocurrencies": "Criptomonedas",
    "usdtNowPayments": "USDT y más (NOWPayments)",
    "inAppPurchase": "Compra in-app",
    "updateNow": "Actualizar",
    "filterByCountry": "Filtrar por país",
    "callAction": "Llamar",
    "anotherPkSameRival": "¿Quieres hacer otra PK con el mismo rival?",
    "timeUpAnotherPk": "El tiempo terminó. ¿Quieres otra PK?",
    "wompiLocalChargeHint": "El cobro se procesará en moneda local (COP) según la tasa de cambio actual equivalente a $@amount USD.",
    "continueToPayment": "Continuar al pago",
    "rechargeHistory": "Historial de recargas",
    "noRecharges": "Sin recargas",
    "noRechargesDesc": "Tus compras de monedas aparecerán aquí.",
    "rechargeSourceAdmin": "Admin",
    "rechargeSourceCrypto": "Cripto (NOWPayments)",
    "rechargeSourceWompi": "Tarjeta (Wompi)",
    "resumeLive": "Reanudar",
    "pauseLive": "Pausar",
    "resumeLiveSubtitle": "Continuar la transmisión",
    "pauseLiveSubtitle": "Pausar video temporalmente",
    "unmuteMic": "Activar micrófono",
    "muteMic": "Silenciar micrófono",
    "micMutedSubtitle": "El mic está muteado",
    "micOpenSubtitle": "El mic está abierto",
    "turnOffCamera": "Apagar cámara",
    "liveVideoControl": "Control de video en vivo",
    "videoQuality": "Calidad de video",
    "currentQuality": "Actual: @quality",
    "qualityLowMediumHigh": "Baja / Media / Alta",
    "qualityHint": "Entras en Baja. Súbela si tu señal mejora.",
    "qualityLowHint": "180p · menos datos",
    "qualityMediumHint": "360p · equilibrado",
    "qualityHighHint": "720p · máxima calidad",
    "matchModeRandom": "Aleatorio",
    "matchAnyClient": "Cualquier cliente",
    "matchAnyStreamer": "Cualquier streamer",
    "matchModeGoddess": "Diosa",
    "matchTopRated": "Las mejor valoradas",
    "unBlock": "Desbloquear",
    "myLevel": "Mi nivel",
    "recharge": "Recargar",
    "equip": "Equipar",
    "equipped": "Equipado",
    "dressingCenter": "Centro de vestuario",
    "privilegeHub": "Mis privilegios",
    "leaderboard": "Clasificación",
    "youAre": "Eres",
    "paymentMethod": "Método de pago",
    "coinsCount": "@count monedas",
    "noPaymentMethods": "No hay métodos de pago disponibles.",
    "appStorePlayStore": "App Store / Play Store",
    "waitingCardPayment": "Esperando tu pago con tarjeta…",
    "waitingCryptoPayment": "Esperando tu pago en crypto…",
    "clickToMatch": "Toca para hacer Match",
    "searchingMatch": "Buscando coincidencia…",
    "freeMatchesCount": "Gratis @used/@quota",
    "membership": "Membresía",
    "myCoinsCount": "Mis monedas: @coins",
    "giftsSent": "regalos enviados",
    "liveTab": "LIVE",
    "chat": "Chat",
    "matchLabel": "Match",
    "planInicial": "Inicial",
    "planBasico": "Básico",
    "planPopular": "Popular",
    "planPremium": "Premium",
    "planVip": "VIP",
    "planGrande": "Grande",
    "frameSilver": "Marco plata",
    "frameGold": "Marco oro",
    "frameDiamond": "Marco diamante",
    "youAreSvip": "Eres SVIP",
    "searchingAnotherLive": "Buscando otro LIVE…",
    "hostDisconnectedSeeking": "Host desconectado…\nBuscando otro LIVE en @sec s",
    "livePausedHostInCall": "LIVE pausado · Host en llamada",
    "livePausedInCall": "LIVE pausado · En llamada",
    "waitingForHost": "Esperando al host…",
    "enablingCamera": "Activando cámara…",
    "waitingForClient": "Esperando cliente…",
    "tapToReceiveClients": "Toca para recibir clientes",
    "waitingVideo": "Esperando video…",
    "unreadChats": "Chats sin leer",
    "tapToReply": "Toca para responder…",
    "noMoreMatchClients": "No hay más clientes en Match ahora",
    "noMoreMatchStreamers": "No hay más streamers en Match ahora",
    "noGoddessInMatch": "No hay Diosa en Match ahora. Prueba Aleatorio.",
    "noStreamersInMatch": "No hay streamers en Match ahora",
    "noClientsWithFilters": "No hay clientes con estos filtros",
    "noStreamersWithFilters": "No hay streamers con estos filtros",
    "needCoinsToSearchMatch": "Necesitas @coins monedas para buscar Match",
    "needCoinsForMatch": "Necesitas @coins monedas para el Match",
    "needCoinsForMinutes": "Necesitas @coins monedas para @minutes min",
    "coinsUsedToViewMatch": "Se usaron @count monedas para ver Match",
    "yourBalanceCoins": "Tu saldo: @coins",
    "statusActive": "Activa",
    "statusInactive": "Inactiva",
    "waitingForOtherUser": "Esperando al otro usuario…",
    "tapToOpenCamera": "Toca para abrir la cámara",
    "tapToOpenCameraBrowser": "Toca para abrir la cámara (permiso del navegador)",
    "waitingCamera": "Esperando cámara…",
    "noGiftsInCatalog": "No hay regalos en el catálogo",
    "noActiveGifts": "No hay regalos activos",
    "noIncentivizedGifts": "No hay regalos incentivados configurados",
    "noRivalsInLive": "No hay rivales en LIVE disponibles.\nSolo aparecen hosts en transmisión y fuera de PK.",
    "noTasksForNow": "No hay tareas por ahora",
    "noWithdrawalMethods": "No hay métodos de retiro habilitados",
    "confirmingPayment": "Confirmando el pago…",
    "confirmingBlockchain": "Confirmando en blockchain…",
    "partialPaymentDetected": "Pago parcial detectado. Completa el monto.",
    "paymentNotCompleted": "El pago no se completó.",
    "gift": "Regalo",
}

PT_MISSING: dict[str, str] = {
    "language": "Idioma",
    "all": "Todos",
    "feed": "Feed",
    "following": "Seguindo",
    "post": "PUBLICAR",
    "nearby": "Perto",
    "next": "Seguinte",
    "agreeToPolicy": "Ao continuar, você concorda com a",
    "continueAsGuest": "Continuar como convidado",
    "joinToContinue": "Vincular conta",
    "joinToContinueDescription": "Você pode continuar usando o app como Guest. Vincule um email se quiser recuperar esta conta depois.",
    "joinNow": "Vincular agora",
    "guestAccountExpires": "Contas Guest não expiram. Têm os mesmos privilégios de um cliente.",
    "supportChat": "Chat de suporte",
    "supportChatSubtitle": "Criar um ticket de suporte",
    "supportChatHint": "Descreva o seu problema…",
    "supportChatEmpty": "Escreva a primeira mensagem para abrir um ticket.",
    "supportBadge": "SUPORTE",
    "editCalls": "Editar chamadas",
    "callPriceScreenTitle": "Preço da chamada",
    "myPrivateCallPrice": "Preço da minha chamada privada",
    "myCurrentGrade": "Meu nível atual",
    "callPriceTipsTitle": "Dica de preço da chamada",
    "callPriceLockedHint": "Só os rangos A e S podem editar o preço. Os demais veem o valor fixo da plataforma.",
    "confirm": "Confirmar",
    "clientsRanking": "Ranking de clientes",
    "streamersRanking": "Ranking de streamers",
    "callStreamerInCall": "Esta streamer já está em uma chamada",
    "callStreamerOffline": "Esta streamer está offline",
    "onlineNow": "Online",
    "callOnlyFromLive": "Entre no LIVE para ligar",
    "joinThisLive": "Entrar no LIVE",
    "callEndedInsufficientCoins": "Você não tem coins suficientes para continuar a chamada",
    "callEndedClientNoCoins": "A chamada terminou: o cliente ficou sem coins",
    "liveBadge": "Ao vivo",
    "peopleWatching": "@count assistindo",
    "lastCallMinutesAgo": "ÚLTIMA CHAMADA HÁ @min MIN",
    "lastCallHoursAgo": "ÚLTIMA CHAMADA HÁ @hours H",
    "impression": "Impressão",
    "rankLabel": "Rank: @grade",
    "rateImpression": "Avaliar",
    "herTraits": "Como ela se define",
    "otherTraits": "Mais qualidades",
    "maxTraitsHint": "Escolha até @count",
    "ratingSaved": "Obrigado por avaliar",
    "offlineBadge": "Offline",
    "calling": "Chamando…",
    "ringing": "Tocando…",
    "connecting": "Conectando…",
    "receiveMatch": "Receber Match",
    "receiveMatchHint": "Permitir que clientes façam Match com você",
    "networkWifi": "Wi‑Fi",
    "blockUserConfirmation": "Tem certeza de que deseja bloquear este usuário? Você não verá mais o conteúdo dele.",
    "deleteAccountMessage": "Deseja realmente excluir sua conta? Todos os seus dados serão apagados.",
    "sessionExpiredTitle": "Sessão expirada – Login em outro dispositivo",
    "sessionExpiredMessage": "Por segurança, @app_name permite apenas uma sessão ativa por conta.",
    "freezeDescription": "Sua conta foi congelada temporariamente. Entre em contato se achar que é um engano.",
    "textRejectedAndContainsSuchThings": "O texto foi recusado porque inclui: ",
    "mediaRejectedAndContainsSuchThings": "A mídia foi recusada porque inclui: ",
    "stopBattleDescription": "Tem certeza de que deseja encerrar a batalha? Esta ação não pode ser desfeita.",
    "invitedListEmptyDescription": "Você ainda não convidou ninguém. Os convidados aparecerão aqui.",
    "noUserReelsDescription": "Este usuário ainda não publicou reels.",
    "noMyPostsTitle": "Você ainda não compartilhou publicações",
    "noUserPostsDescription": "Este usuário ainda não compartilhou publicações.",
    "cannotLeaveDuringBattle": "Você não pode sair do LIVE durante uma batalha.",
    "exitLiveStreamDescription": "Tem certeza de que deseja sair do LIVE?\nSe o stream terminou, você não poderá voltar.",
    "qrCodeMessage": "artista. Inspiro-me na natureza e na vida urbana. Vamos conversar.",
    "postCommentEmptyDescription": "Esta publicação não tem comentários. Participe e compartilhe sua opinião.",
    "blockListEmptyDescription": "Os usuários que você bloquear aparecerão aqui.",
    "registrationBonusTitle": "Bônus de boas-vindas creditado na sua carteira!",
    "tasksEndToday": "As tarefas de hoje terminam em",
    "liveMinutesLabel": "Tempo LIVE",
    "goDoTask": "Ir",
    "goToLiveCategory": "Ir ao LIVE",
    "goToMatchCategory": "Ir ao Match",
    "goToChatCategory": "Ir ao Chat",
    "goToProfileCategory": "Ir ao Perfil",
    "goToExploreCategory": "Ir a Explorar",
    "goToFeedCategory": "Criar publicação",
    "nextTaskUnlocked": "Próxima tarefa desbloqueada",
    "completeFirstTaskToContinue": "Conclua a Tarefa 1 para ir a esta categoria",
    "weeklyLevel": "Nível",
    "streamerAverage": "Média",
    "streamerAverageNeed": "Você precisa de @n pontos para chegar a @grade",
    "streamerAverageNeedOne": "Você precisa de 1 ponto para chegar a @grade",
    "avgCoins": "Moedas",
    "avgCalls": "Chamadas",
    "avgLive": "Conexão",
    "avgActivity": "Atividade",
    "avgQuality": "Qualidade",
    "callGoalNotMet": "Meta de chamadas não cumprida",
    "callGoalMet": "Meta de chamadas cumprida",
    "detail": "Detalhe",
    "todaysCalls": "Chamadas de hoje",
    "diamonds": "Diamantes",
    "gems": "Gemas",
    "onlineTime": "Tempo online",
    "avgCallDuration": "Duração média",
    "positiveRating": "Avaliação positiva",
    "todaysEarnings": "Ganhos de hoje",
    "earningsFromCalls": "Ganhos de chamadas",
    "earningsFromGifts": "Ganhos de presentes",
    "earningsFromTasks": "Ganhos de tarefas",
    "earningsFromInvites": "Ganhos de convites",
    "managedEarnings": "Ganhos gerenciados",
    "rejections": "Rejeições",
    "rejectionRate": "Taxa de rejeição",
    "weeklyLevelPrivateLiveOnly": "Nível semanal (apenas privado e LIVE)",
    "category": "Categoria",
    "thisWeek": "Esta semana",
    "lastWeek": "Semana passada",
    "levelResponseRate": "Taxa de resposta do nível",
    "levelAvgDuration": "Duração média do nível",
    "levelCalls": "Chamadas do nível",
    "levelUpdateTime": "Atualização de nível",
    "currentLevelBenefits": "Benefícios do nível atual",
    "connected": "Conectada",
    "disconnected": "Desconectada",
    "withdraw": "Sacar",
    "freeMatchesUsed": "Você já usou seus 2 Matches grátis de hoje! Recarregue coins e continue.",
    "vipBadge": "VIP",
    "waitingBattleResponse": "Aguardando resposta da batalha…",
    "waitingForUser": "Aguardando @name…",
    "walletHistory": "Histórico da carteira",
    "walletIncome": "entradas",
    "walletWithdrawLabel": "saques",
    "walletGiftFrom": "Presente de @name",
    "walletGiftLiveFrom": "Presente no LIVE de @name",
    "walletGiftChatFrom": "Presente no chat de @name",
    "walletGiftCallFrom": "Presente na chamada de @name",
    "walletPrivateCallWith": "Chamada privada com @name",
    "walletMatchWith": "Match com @name",
    "walletNoHistory": "Sem movimentos",
    "walletNoHistoryDesc": "Aqui você verá as moedas de LIVE, chat, chamadas e outros presentes.",
    "walletFilterAll": "Todo o histórico",
    "walletFilterLive": "Do LIVE",
    "walletFilterChat": "Do chat",
    "walletFilterCalls": "Das chamadas",
    "walletFilterGifts": "Outros presentes",
    "walletRechargeItem": "Recarga de moedas",
    "walletWithdrawItem": "Saque",
    "walletExchangeRate": "Taxa de câmbio: @coins Coins = @currency1",
    "newFollowers": "Novos seguidores",
    "walletAgencyShareFrom": "Comissão de @name",
    "agencyDashboardTitle": "Agência",
    "agencyYourStreamers": "Seus streamers afiliados",
    "agencyNoStreamers": "Você ainda não tem streamers",
    "agencyCreateStreamerHint": "Crie uma conta Streamer afiliada à sua agência.",
    "agencyCreateStreamer": "Criar streamer",
    "agencyStreamerEarned": "O streamer ganhou",
    "agencyYourShare": "Sua comissão",
    "agencyMonth": "Este mês",
    "agencyLifetime": "Total",
    "agencyWalletHint": "10% da margem App dos seus streamers",
    "saveRating": "Salvar",
    "rating": "Avaliação",
    "addMore": "Adicionar mais",
    "locationError": "Erro de localização",
    "kycCheckStatus": "Já terminei — verificar status",
    "retry": "Tentar de novo",
    "enableCamera": "Ativar câmera",
    "withdrawMethod": "Método de saque",
    "payoutAccount": "Conta / wallet de recebimento",
    "battleEndedTitle": "Batalha encerrada",
    "noLeave": "Não, sair",
    "yesAnotherPk": "Sim, outro PK",
    "notNow": "Agora não",
    "payCardPseNequi": "Cartão / Nequi / QR",
    "payWompi": "Wompi · Colômbia e Internacional",
    "cryptocurrencies": "Criptomoedas",
    "usdtNowPayments": "USDT e mais (NOWPayments)",
    "inAppPurchase": "Compra no app",
    "updateNow": "Atualizar",
    "filterByCountry": "Filtrar por país",
    "callAction": "Ligar",
    "anotherPkSameRival": "Quer fazer outro PK com o mesmo rival?",
    "timeUpAnotherPk": "O tempo acabou. Quer outro PK?",
    "wompiLocalChargeHint": "A cobrança será processada em moeda local (COP) conforme a taxa de câmbio atual equivalente a $@amount USD.",
    "continueToPayment": "Continuar para o pagamento",
    "rechargeHistory": "Histórico de recargas",
    "noRecharges": "Sem recargas",
    "noRechargesDesc": "Suas compras de moedas aparecerão aqui.",
    "rechargeSourceAdmin": "Admin",
    "rechargeSourceCrypto": "Cripto (NOWPayments)",
    "rechargeSourceWompi": "Cartão (Wompi)",
    "resumeLive": "Retomar",
    "pauseLive": "Pausar",
    "resumeLiveSubtitle": "Continuar a transmissão",
    "pauseLiveSubtitle": "Pausar o vídeo temporariamente",
    "unmuteMic": "Ativar microfone",
    "muteMic": "Silenciar microfone",
    "micMutedSubtitle": "O microfone está mudo",
    "micOpenSubtitle": "O microfone está ligado",
    "turnOffCamera": "Desligar câmera",
    "liveVideoControl": "Controle de vídeo ao vivo",
    "videoQuality": "Qualidade de vídeo",
    "currentQuality": "Atual: @quality",
    "qualityLowMediumHigh": "Baixa / Média / Alta",
    "qualityHint": "Você começa em Baixa. Aumente se o sinal melhorar.",
    "qualityLowHint": "180p · menos dados",
    "qualityMediumHint": "360p · equilibrado",
    "qualityHighHint": "720p · máxima qualidade",
    "matchModeRandom": "Aleatório",
    "matchAnyClient": "Qualquer cliente",
    "matchAnyStreamer": "Qualquer streamer",
    "matchModeGoddess": "Deusa",
    "matchTopRated": "As melhor avaliadas",
    "unBlock": "Desbloquear",
    "myLevel": "Meu nível",
    "recharge": "Recarregar",
    "equip": "Equipar",
    "equipped": "Equipado",
    "dressingCenter": "Centro de figurinos",
    "privilegeHub": "Meus privilégios",
    "leaderboard": "Ranking",
    "youAre": "Você é",
    "paymentMethod": "Método de pagamento",
    "coinsCount": "@count moedas",
    "noPaymentMethods": "Não há métodos de pagamento disponíveis.",
    "appStorePlayStore": "App Store / Play Store",
    "waitingCardPayment": "Aguardando seu pagamento com cartão…",
    "waitingCryptoPayment": "Aguardando seu pagamento em cripto…",
    "clickToMatch": "Toque para fazer Match",
    "searchingMatch": "Procurando coincidência…",
    "freeMatchesCount": "Grátis @used/@quota",
    "membership": "Assinatura",
    "myCoinsCount": "Minhas moedas: @coins",
    "giftsSent": "presentes enviados",
    "liveTab": "LIVE",
    "chat": "Chat",
    "matchLabel": "Match",
    "planInicial": "Inicial",
    "planBasico": "Básico",
    "planPopular": "Popular",
    "planPremium": "Premium",
    "planVip": "VIP",
    "planGrande": "Grande",
    "frameSilver": "Moldura prata",
    "frameGold": "Moldura ouro",
    "frameDiamond": "Moldura diamante",
    "youAreSvip": "Você é SVIP",
    "searchingAnotherLive": "Procurando outro LIVE…",
    "hostDisconnectedSeeking": "Host desconectado…\nProcurando outro LIVE em @sec s",
    "livePausedHostInCall": "LIVE pausado · Host em chamada",
    "livePausedInCall": "LIVE pausado · Em chamada",
    "waitingForHost": "Aguardando o host…",
    "enablingCamera": "Ativando câmera…",
    "waitingForClient": "Aguardando cliente…",
    "tapToReceiveClients": "Toque para receber clientes",
    "waitingVideo": "Aguardando vídeo…",
    "unreadChats": "Chats não lidos",
    "tapToReply": "Toque para responder…",
    "noMoreMatchClients": "Não há mais clientes no Match agora",
    "noMoreMatchStreamers": "Não há mais streamers no Match agora",
    "noGoddessInMatch": "Não há Deusa no Match agora. Tente Aleatório.",
    "noStreamersInMatch": "Não há streamers no Match agora",
    "noClientsWithFilters": "Não há clientes com estes filtros",
    "noStreamersWithFilters": "Não há streamers com estes filtros",
    "needCoinsToSearchMatch": "Você precisa de @coins moedas para buscar Match",
    "needCoinsForMatch": "Você precisa de @coins moedas para o Match",
    "needCoinsForMinutes": "Você precisa de @coins moedas para @minutes min",
    "coinsUsedToViewMatch": "Foram usadas @count moedas para ver Match",
    "yourBalanceCoins": "Seu saldo: @coins",
    "statusActive": "Ativa",
    "statusInactive": "Inativa",
    "waitingForOtherUser": "Aguardando o outro usuário…",
    "tapToOpenCamera": "Toque para abrir a câmera",
    "tapToOpenCameraBrowser": "Toque para abrir a câmera (permissão do navegador)",
    "waitingCamera": "Aguardando câmera…",
    "noGiftsInCatalog": "Não há presentes no catálogo",
    "noActiveGifts": "Não há presentes ativos",
    "noIncentivizedGifts": "Não há presentes incentivados configurados",
    "noRivalsInLive": "Não há rivais em LIVE disponíveis.\nSó aparecem hosts em transmissão e fora de PK.",
    "noTasksForNow": "Não há tarefas por agora",
    "noWithdrawalMethods": "Não há métodos de saque habilitados",
    "confirmingPayment": "Confirmando o pagamento…",
    "confirmingBlockchain": "Confirmando na blockchain…",
    "partialPaymentDetected": "Pagamento parcial detectado. Complete o valor.",
    "paymentNotCompleted": "O pagamento não foi concluído.",
    "gift": "Presente",
    "balance": "Saldo",
    "collected": "Acumulado*",
    "gifted": "Presenteado*",
    "purchased": "Comprado*",
    "taskCategoryLive": "LIVE",
    "taskCategoryOther": "Outras",
    "tasksOnlyForStreamers": "As tarefas estão disponíveis apenas para streamers.",
    "withdrawalPointsProgress": "Pontos para saque @current / @target pts",
    "liveAndOtherPoints": "LIVE: @live/@liveMax · Outras: @other/@otherMax",
    "todayLiveOtherGoal": "Hoje LIVE @live + Outras @other (meta @target)",
    "tasksWorkHint": "LIVE 120 pts + Outras 30 pts = 150 para saque. Grau B/C: tarefas de chamadas privadas.",
    "callPriceTip1": "O preço da chamada é ajustado pela plataforma conforme o seu desempenho.",
    "callPriceTip2": "Para mudar a faixa de preço, fale com o suporte ou com o seu agente.",
    "callPriceTip3": "Subir o preço pode aumentar a renda, mas não faça isso de uma vez.",
    "callPriceTip4": "Se ao subir o preço as chamadas caírem, restaure o preço anterior.",
    "callPriceTip5": "Teste vários valores até equilibrar volume de chamadas e renda.",
    "callPriceTipRangeHint": "Faixa A: preço dentro do limite A. Faixa S: limite mais amplo.",
    "searchUsersEllipsis": "Buscar usuários…",
    "durationMinutesAbbr": "@count min",
    "durationSecondsAbbr": "@count s",
    "durationMinSec": "@m min @s s",
    "minutesUnit": "min",
    "activeFilter": "Ativos",
    "clearFilters": "Limpar",
    "clientsOnlyMessages": "Com clientes você só pode enviar mensagens",
    "streamerNotReceivingCalls": "Esta streamer não recebe chamadas agora",
    "liveNotAvailable": "O LIVE não está disponível",
    "enterMatchToWaitClients": "Entre no Match para abrir a câmera e esperar clientes",
    "liveTask1": "Tarefa LIVE 1",
    "liveTask2": "Tarefa LIVE 2",
    "liveTask3": "Tarefa LIVE 3",
    "liveTask4": "Tarefa LIVE 4",
    "liveMaxTask": "Tarefa LIVE Máx",
    "liveTask1Desc": "60 min LIVE + meta de coins 1",
    "liveTask2Desc": "90 min LIVE + meta de coins 2",
    "liveTask3Desc": "120 min LIVE + meta de coins 3",
    "liveTask4Desc": "240 min LIVE + meta de coins 4",
    "liveMaxTaskDesc": "150 min LIVE + meta máxima de coins (completa as anteriores)",
    "liveTasksCategory": "Tarefas LIVE",
    "otherActivitiesCategory": "Outras atividades",
    "privateCallTasksBc": "Tarefas de chamada privada B/C",
    "interactionsTask": "Interações",
    "interactionsTaskDesc": "Complete 10 interações (mensagens, likes, respostas)",
    "privateCall5MinTask": "Chamada privada 5 min",
    "privateCall5MinTaskDesc": "Complete 1 chamada privada de pelo menos 5 minutos faturáveis",
    "dailyActivityTask": "Atividade diária",
    "dailyActivityTaskDesc": "Publique um post ou atualize o seu perfil hoje",
    "taskT01": "T01 — 5 chamadas de 5 min",
    "taskT01Desc": "Complete 5 chamadas faturáveis distintas de pelo menos 5 minutos",
    "taskT02": "T02 — 10 Matches",
    "taskT02Desc": "Complete 10 Matches (20 segundos grátis completos)",
    "taskT03": "T03 — Presentes em 5 chamadas",
    "taskT03Desc": "Receba pelo menos 1 presente em 5 chamadas distintas",
    "taskT04": "T04 — Publicar story",
    "taskT04Desc": "Publique 1 story válida",
    "taskT05": "T05 — Responder 10 mensagens",
    "taskT05Desc": "Responda 10 mensagens recebidas distintas",
    "taskT06": "T06 — Chamada de 20 min",
    "taskT06Desc": "Complete 1 chamada faturável de pelo menos 20 minutos",
    "taskT07": "T07 — Coins de presentes",
    "taskT07Desc": "Acumule coins de presentes",
    "taskT08": "T08 — 6 h online",
    "taskT08Desc": "Acumule 6 horas de conexão válida",
    "callCostPerMin": "@coins/min",
}

ADMIN_ES: dict[str, str] = {
    "Streamer Average": "Average de streamers",
    "Solo aplica a usuarios con rol Streamer. Independiente de los puntos de retiro.": "Solo aplica a usuarios con rol Streamer. Independiente de los puntos de retiro.",
    "Ventana y protecciones": "Ventana y protecciones",
    "Días móviles": "Días móviles",
    "Días para subir/bajar": "Días para subir/bajar",
    "Segundos mín. llamada": "Segundos mín. llamada",
    "Pesos (%)": "Pesos (%)",
    "Monedas": "Monedas",
    "Llamadas": "Llamadas",
    "Conexión": "Conexión",
    "Actividad": "Actividad",
    "Calidad": "Calidad",
    "Rangos de nivel (AVG)": "Rangos de nivel (AVG)",
    "Nivel": "Nivel",
    "Recalcular streamers": "Recalcular streamers",
    "Recalcular Average y nivel de todos los streamers?": "¿Recalcular Average y nivel de todos los streamers?",
    "PlayStore Product Id": "ID de producto Play Store",
    "AppStore Product Id": "ID de producto App Store",
    "Add Package": "Agregar paquete",
    "Edit Package": "Editar paquete",
    "Coin Amount": "Cantidad de coins",
    "Bonus %": "Bonus %",
    "Sort": "Orden",
    "gift(s)": "regalo(s)",
    "Filter gifts by category. Drag order via sort order when editing.": "Filtra regalos por categoría. Arrastra el orden al editar.",
    "No gifts in this category": "No hay regalos en esta categoría",
    "Assign the gift to a category to organize the app catalog.": "Asigna el regalo a una categoría para organizar el catálogo.",
    "Select category": "Seleccionar categoría",
    "Create a category first": "Crea una categoría primero",
    "Coin Price": "Precio en coins",
    "Add Gift": "Agregar regalo",
    "Edit Gift": "Editar regalo",
    "Categories": "Categorías",
    "New": "Nuevo",
    "Showing": "Mostrando",
    "to": "a",
    "of": "de",
    "entries": "registros",
    "Image (Select To Edit Only)": "Imagen (solo si vas a cambiarla)",
    "Add": "Agregar",
    "Add Dummy Live": "Agregar LIVE dummy",
    "Add Item": "Agregar ítem",
    "Add Onboarding": "Agregar onboarding",
    "Add Username": "Agregar usuario",
    "Add Withdrawal Gateways": "Agregar métodos de retiro",
    "Added By": "Agregado por",
    "Accept Report": "Aceptar reporte",
    "Account hint": "Ayuda de cuenta",
    "Allow Withdrawal Of Coins": "Permitir retiro de coins",
    "App Store Download Link": "Link de descarga App Store",
    "Benefits (one per line)": "Beneficios (uno por línea)",
    "Bonus": "Bonus",
    "Bundle Id / Package Name": "Bundle Id / Package Name",
    "Call Coins": "Coins de llamada",
    "Call Request Coins": "Coins de solicitud de llamada",
    "Call requests priced by the callee user level (configured in User Levels).": "Las solicitudes de llamada se cobran según el nivel del usuario (configurado en Niveles).",
    "Callee": "Receptor",
    "Caller": "Quien llama",
    "Calls": "Llamadas",
    "Can Go Live": "Puede ir a LIVE",
    "Can Receive Calls": "Puede recibir llamadas",
    "Cancel": "Cancelar",
    "Check Validation": "Verificar validación",
    "Close ticket": "Cerrar ticket",
    "Closed": "Cerrado",
    "Color": "Color",
    "Commission %": "Comisión %",
    "Complete": "Completar",
    "Confirm Password": "Confirmar contraseña",
    "Created": "Creado",
    "Database Password": "Contraseña de base de datos",
    "Database Username": "Usuario de base de datos",
    "Date": "Fecha",
    "Deep Linking": "Deep linking",
    "Deeplink Settings": "Ajustes de deeplink",
    "Default % if a method has no custom rate. Methods can override this.": "Porcentaje por defecto si el método no tiene tarifa propia. Los métodos pueden sobrescribirlo.",
    "Delete": "Eliminar",
    "Details": "Detalles",
    "Disable": "Desactivar",
    "Download CSV": "Descargar CSV",
    "Download the App Now": "Descarga la app ahora",
    "Dummy Live Streams": "LIVE dummy",
    "Edit": "Editar",
    "Edit CSV": "Editar CSV",
    "Edit Dummy Live": "Editar LIVE dummy",
    "Edit Item": "Editar ítem",
    "Empty = use global %": "Vacío = usar % global",
    "Enable": "Activar",
    "Enabled": "Activo",
    "Fluid": "Fluido",
    "Freeze": "Congelar",
    "Full information block on the Retiro screen.": "Bloque de información completo en la pantalla de retiro.",
    "GIF Supported": "GIF compatible",
    "GIPHY": "GIPHY",
    "Gift": "Regalo",
    "Grant SVIP": "Otorgar SVIP",
    "Last message": "Último mensaje",
    "Likes": "Me gusta",
    "Link": "Link",
    "Links": "Links",
    "Log-in": "Iniciar sesión",
    "Longitude": "Longitud",
    "Max. Comment Reply/Day": "Máx. respuestas a comentarios/día",
    "Max. Comments/Day": "Máx. comentarios/día",
    "Max. Post Upload/Day": "Máx. publicaciones/día",
    "Min. Followers needed to go Live": "Mín. de seguidores para ir a LIVE",
    "Mobile": "Móvil",
    "Moderator": "Moderador",
    "Name": "Nombre",
    "Open": "Abierto",
    "Optional": "Opcional",
    "Other Details": "Otros detalles",
    "PLUS+ Membership Enabled": "Membresía PLUS+ activa",
    "PLUS+ Membership Price (USD)": "Precio PLUS+ (USD)",
    "Package Name": "Nombre del paquete",
    "Payout type": "Tipo de pago",
    "Play Store Download Link": "Link de descarga Play Store",
    "Position": "Posición",
    "Post": "Publicación",
    "Post Count": "N.º de publicaciones",
    "REWARD SETTINGS": "AJUSTES DE RECOMPENSA",
    "Receive Message": "Recibir mensaje",
    "Reject": "Rechazar",
    "Reject Report": "Rechazar reporte",
    "Remove SVIP": "Quitar SVIP",
    "Repeat": "Repetir",
    "Replies": "Respuestas",
    "Request Number": "N.º de solicitud",
    "Required": "Obligatorio",
    "Rules, fees, processing time, support notes…": "Reglas, comisiones, tiempo de proceso, notas de soporte…",
    "SHA 256 Keys": "Claves SHA-256",
    "SVIP Level": "Nivel SVIP",
    "Select Category": "Seleccionar categoría",
    "Select Dummy User": "Seleccionar usuario dummy",
    "Send": "Enviar",
    "Show on Honor Wall": "Mostrar en muro de honor",
    "Show password": "Mostrar contraseña",
    "Slug": "Slug",
    "Sortable": "Ordenable",
    "Support Ticket": "Ticket de soporte",
    "Team Id": "Team Id",
    "Ticket": "Ticket",
    "URI Schema": "Esquema URI",
    "Unlock Dressing Center": "Desbloquear vestuario",
    "Unlock Endless Surprises Inside!": "¡Desbloquea sorpresas dentro!",
    "Unlock Level": "Nivel de desbloqueo",
    "Usernames": "Usuarios",
    "Users can withdraw from this USD amount onward.": "Los usuarios pueden retirar a partir de este monto en USD.",
    "VIP duration (days)": "Duración VIP (días)",
    "Video": "Video",
    "View Content": "Ver contenido",
    "Wall of Honor": "Muro de honor",
    "Watermark Videos": "Videos con marca de agua",
    "Withdrawal Commission (%)": "Comisión de retiro (%)",
    "Withdrawal Info (shown in app)": "Info de retiro (se muestra en la app)",
    "ZEGO CLOUD SETTINGS": "AJUSTES ZEGO CLOUD",
    "Zego Cloud App ID": "Zego Cloud App ID",
    "Zego Cloud App Sign": "Zego Cloud App Sign",
    "privacyPolicy": "Política de privacidad",
    "termsOfUses": "Términos de uso",
    "viewSubCategories": "Ver subcategorías",
    "Configure ladder benefits: call price, receive calls, SVIP, dressing unlock and honor wall.": "Configura beneficios por nivel: precio de llamada, recibir llamadas, SVIP, vestuario y muro de honor.",
    "Frames and badges unlocked by user level. Equipped on the user profile in the app.": "Marcos y badges que se desbloquean por nivel. Se equipan en el perfil de la app.",
    "*lifetime": "de por vida",
}


def write_map(
    fp, map_name: str, items: list[tuple[str, str]], lkeys: dict[str, str]
) -> None:
    """LKey constants that share the same English string collide in a const map."""
    seen: set[str] = set()
    fp.write(f"const {map_name} = <String, String>{{\n")
    for name, val in items:
        key = lkeys[name]
        if key in seen:
            continue
        seen.add(key)
        fp.write(f"  LKey.{name}: '{dart_escape(val)}',\n")
    fp.write("};\n\n")


def _unique_csv_rows(rows: list[tuple[str, str]]) -> list[tuple[str, str]]:
    seen: set[str] = set()
    out: list[tuple[str, str]] = []
    for k, v in rows:
        if k in seen:
            continue
        seen.add(k)
        out.append((k, v))
    return out


def rewrite_csv(path: Path, header: tuple[str, str], rows: list[tuple[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(list(header))
        for k, v in rows:
            w.writerow([k, v])


def pick_translation(
    name: str,
    en_val: str,
    lkey_val: str,
    extra: dict[str, str],
    csv_map: dict[str, str],
) -> str:
    if name in extra:
        return extra[name]
    csv_val = match_csv(lkey_val, csv_map)
    identity = (not csv_val) or csv_val.strip() in {en_val.strip(), lkey_val.strip()}
    if csv_val and not identity:
        return csv_val
    return csv_val or en_val


def append_csv_missing(path: Path, header: tuple[str, str], rows: list[tuple[str, str]]) -> int:
    existing = load_csv(path)
    existing_norm = {norm(k) for k in existing}
    to_add = [(k, v) for k, v in rows if norm(k) not in existing_norm]
    if not to_add:
        return 0
    all_rows: list[tuple[str, str]] = list(existing.items()) + to_add
    rewrite_csv(path, header, all_rows)
    return len(to_add)


def collect_admin_keys() -> set[str]:
    keys: set[str] = set()
    pat = re.compile(r"__\(\s*['\"](.+?)['\"]\s*\)")
    for p in list(VIEWS.rglob("*.blade.php")) + list((BACKEND / "app").rglob("*.php")):
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for m in pat.finditer(text):
            keys.add(m.group(1))
    return keys


def main() -> None:
    src = KEYS_FILE.read_text(encoding="utf-8")
    lkeys = parse_lkeys(src)
    print(f"Parsed LKeys: {len(lkeys)}")

    es_csv = load_csv(CSV_DIR / "es.csv")
    pt_csv = load_csv(CSV_DIR / "pt.csv")
    zh_csv = load_csv(CSV_DIR / "zh.csv")
    ar_csv = load_csv(CSV_DIR / "ar.csv")
    ru_csv = load_csv(CSV_DIR / "ru.csv")
    uk_csv = load_csv(CSV_DIR / "uk.csv")

    app_en: list[tuple[str, str]] = []
    app_es: list[tuple[str, str]] = []
    app_pt: list[tuple[str, str]] = []
    app_zh: list[tuple[str, str]] = []
    app_ar: list[tuple[str, str]] = []
    app_ru: list[tuple[str, str]] = []
    app_uk: list[tuple[str, str]] = []

    missing_es: list[str] = []
    for name, val in lkeys.items():
        en_val = EN_FOR_SPANISH_KEYS.get(name, val)
        es_val = ES_MISSING.get(name) or match_csv(val, es_csv)
        if es_val is None:
            if looks_spanish(val) or name in EN_FOR_SPANISH_KEYS:
                es_val = val
            else:
                es_val = val  # last resort English; counted as missing quality
                missing_es.append(name)
        pt_val = PT_MISSING.get(name) or match_csv(val, pt_csv) or es_val

        app_en.append((name, en_val))
        app_es.append((name, es_val))
        app_pt.append((name, pt_val))
        app_zh.append((name, pick_translation(name, en_val, val, ZH_MISSING, zh_csv)))
        app_ar.append((name, pick_translation(name, en_val, val, AR_MISSING, ar_csv)))
        app_ru.append((name, pick_translation(name, en_val, val, RU_MISSING, ru_csv)))
        app_uk.append((name, pick_translation(name, en_val, val, UK_MISSING, uk_csv)))

    print(f"LKeys still English-as-Spanish (no dedicated ES): {len(missing_es)}")

    en_by = {n: v for n, v in app_en}
    allow_identity = {
        "Instagram",
        "Youtube",
        "SVIP",
        "PLUS+",
        "VIP",
        "TOP",
        "Match",
        "Wi‑Fi",
        "Wi-Fi",
        "GIF",
        "Feed",
        "Chat",
        "LIVE",
        "PK",
        "Off",
        "Email",
        "Nequi",
        "Wompi",
        "USDT",
        "NOWPayments",
        "App Store / Play Store",
        "pts",
    }

    def leftover_identity(pairs: list[tuple[str, str]]) -> list[str]:
        out: list[str] = []
        for name, t in pairs:
            en = en_by[name]
            if t.strip() == en.strip() and en.strip() not in allow_identity:
                out.append(name)
        return out

    zh_left = leftover_identity(app_zh)
    ar_left = leftover_identity(app_ar)
    ru_left = leftover_identity(app_ru)
    uk_left = leftover_identity(app_uk)
    print(f"ZH leftover identity: {len(zh_left)}")
    if zh_left:
        print("  " + ",".join(zh_left))
    print(f"AR leftover identity: {len(ar_left)}")
    print(f"RU leftover identity: {len(ru_left)}")
    print(f"UK leftover identity: {len(uk_left)}")

    catalog_path = LIB_LANG / "lkey_catalog.dart"
    with catalog_path.open("w", encoding="utf-8") as fp:
        fp.write("// GENERATED — do not edit by hand. tools/generate_i18n.py\n")
        fp.write("import 'package:krimson/languages/languages_keys.dart';\n\n")
        fp.write("class LKeyCatalog {\n")
        fp.write("  static const values = <String>[\n")
        for name in lkeys:
            fp.write(f"    LKey.{name},\n")
        fp.write("  ];\n\n")
        fp.write("  static String normalize(String s) =>\n")
        fp.write("      s.replaceAll(RegExp(r'[\\s\\n\\r]+'), '');\n\n")
        fp.write("  /// Re-asocia filas CSV cuya clave perdió saltos de línea.\n")
        fp.write("  static Map<String, String> align(Map<String, String> csv) {\n")
        fp.write("    final byNorm = <String, String>{};\n")
        fp.write("    csv.forEach((k, v) {\n")
        fp.write("      byNorm[normalize(k)] = v;\n")
        fp.write("    });\n")
        fp.write("    final out = Map<String, String>.from(csv);\n")
        fp.write("    for (final key in values) {\n")
        fp.write("      if (out.containsKey(key)) continue;\n")
        fp.write("      final n = normalize(key);\n")
        fp.write("      final mapped = byNorm[n];\n")
        fp.write("      if (mapped != null) out[key] = mapped;\n")
        fp.write("    }\n")
        fp.write("    return out;\n")
        fp.write("  }\n")
        fp.write("}\n")

    fb_path = LIB_LANG / "app_fallbacks.dart"
    with fb_path.open("w", encoding="utf-8") as fp:
        fp.write("// GENERATED — do not edit by hand. tools/generate_i18n.py\n")
        fp.write("import 'package:krimson/languages/languages_keys.dart';\n\n")
        write_map(fp, "appFallbackEn", app_en, lkeys)
        write_map(fp, "appFallbackEs", app_es, lkeys)
        write_map(fp, "appFallbackPt", app_pt, lkeys)
        write_map(fp, "appFallbackZh", app_zh, lkeys)
        write_map(fp, "appFallbackAr", app_ar, lkeys)
        write_map(fp, "appFallbackRu", app_ru, lkeys)
        write_map(fp, "appFallbackUk", app_uk, lkeys)

    csv_rows_es = _unique_csv_rows([(lkeys[n], es) for n, es in app_es])
    csv_rows_pt = _unique_csv_rows([(lkeys[n], pt) for n, pt in app_pt])
    csv_rows_en = _unique_csv_rows([(lkeys[n], en) for n, en in app_en])

    csv_rows_zh = _unique_csv_rows([(lkeys[n], zh) for n, zh in app_zh])
    csv_rows_ar = _unique_csv_rows([(lkeys[n], ar) for n, ar in app_ar])
    csv_rows_ru = _unique_csv_rows([(lkeys[n], ru) for n, ru in app_ru])
    csv_rows_uk = _unique_csv_rows([(lkeys[n], uk) for n, uk in app_uk])

    rewrite_csv(CSV_DIR / "es.csv", ("Language", "Idioma"), csv_rows_es)
    rewrite_csv(CSV_DIR / "pt.csv", ("Language", "Idioma"), csv_rows_pt)
    rewrite_csv(CSV_DIR / "en.csv", ("Language", "Language"), csv_rows_en)
    rewrite_csv(CSV_DIR / "zh.csv", ("Language", "Language"), csv_rows_zh)
    rewrite_csv(CSV_DIR / "ar.csv", ("Language", "Language"), csv_rows_ar)
    rewrite_csv(CSV_DIR / "ru.csv", ("Language", "Language"), csv_rows_ru)
    rewrite_csv(CSV_DIR / "uk.csv", ("Language", "Language"), csv_rows_uk)

    print(f"CSV es/pt/en/zh/ar/ru/uk rewritten with {len(lkeys)} LKeys")

    # Admin JSON
    es_json = json.loads(ES_JSON.read_text(encoding="utf-8"))
    admin_keys = collect_admin_keys()
    missing_admin = sorted(k for k in admin_keys if k not in es_json)
    filled = 0
    for k in missing_admin:
        es_json[k] = ADMIN_ES.get(k, k)
        filled += 1 if k in ADMIN_ES else 0
    for k, v in ADMIN_ES.items():
        if es_json.get(k) in (None, k):
            es_json[k] = v
            filled += 1
    ES_JSON.write_text(
        json.dumps(es_json, ensure_ascii=False, indent=3) + "\n", encoding="utf-8"
    )
    ident = sorted(
        k
        for k in admin_keys
        if es_json.get(k, k) == k and not looks_spanish_admin(k)
    )
    print(f"Admin __() keys: {len(admin_keys)}  newly added: {len(missing_admin)}  translated: {filled}")

    report = APP / "tools" / "missing_translations.txt"
    lines = [
        f"LKeys: {len(lkeys)}",
        f"es.csv rows: {len(csv_rows_es)}",
        f"Admin keys missing before fill: {len(missing_admin)}",
        "",
        "=== LKeys without dedicated ES (fallback = English key) ===",
    ]
    lines.extend(f"  LKey.{n} = {lkeys[n][:80]!r}" for n in missing_es)
    lines.append("")
    lines.append("=== Admin keys still identity (English, not yet translated) ===")
    lines.extend(f"  {k}" for k in ident)
    report.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {catalog_path.name}, {fb_path.name}, {report.name}")
    print(f"Identity admin keys: {len(ident)}")


if __name__ == "__main__":
    main()
