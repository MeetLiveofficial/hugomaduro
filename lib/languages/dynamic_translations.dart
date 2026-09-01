import 'package:get/get.dart';
import 'package:krimson/languages/app_fallbacks.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/languages/lkey_catalog.dart';

class DynamicTranslations extends Translations {
  final Map<String, Map<String, String>> _keys = {};

  @override
  Map<String, Map<String, String>> get keys => _keys;

  /// Carga/mezcla CSV de idiomas y los registra en GetX.
  ///
  /// GetMaterialApp solo hace `Get.addTranslations(translations.keys)` una vez
  /// al montar (cuando el mapa aún está vacío). Sin `Get.appendTranslations`,
  /// `.tr` sigue devolviendo la clave en inglés aunque el locale sea ru/es/pt.
  void addTranslations(Map<String, Map<String, String>> map) {
    map.forEach((lang, translations) {
      final aligned = LKeyCatalog.align(translations);
      if (_keys.containsKey(lang)) {
        _keys[lang]?.addAll(aligned);
      } else {
        _keys[lang] = Map<String, String>.from(aligned);
      }
      Get.appendTranslations({lang: aligned});
    });
    ensureAllFallbacks();
  }

  void ensureAllFallbacks() {
    ensureLiveFallbacks();
    ensureTaskFallbacks();
    ensureAgencyFallbacks();
    ensureCallFallbacks();
    ensureAppFallbacks();
  }

  void _mergeMissing(
    Map<String, Map<String, String>> fallbacks, {
    Map<String, String>? english,
    bool overwrite = false,
  }) {
    final toAppend = <String, Map<String, String>>{};
    fallbacks.forEach((lang, map) {
      final existing = _keys[lang] ?? const <String, String>{};
      final missing = <String, String>{};
      map.forEach((k, v) {
        final current = existing[k];
        final englishVal = english?[k];
        final shouldFill = current == null ||
            (current == k && v != k) ||
            (englishVal != null && current == englishVal && v != current);
        if (overwrite) {
          if (current != v) missing[k] = v;
        } else if (shouldFill) {
          missing[k] = v;
        }
      });
      if (missing.isEmpty) return;
      toAppend[lang] = missing;
      if (_keys.containsKey(lang)) {
        _keys[lang]!.addAll(missing);
      } else {
        _keys[lang] = Map<String, String>.from(missing);
      }
    });
    if (toAppend.isNotEmpty) {
      Get.appendTranslations(toAppend);
    }
  }

  /// Cubre todas las LKey aunque el CSV del servidor aún no se haya re-subido.
  ///
  /// `overwrite: true` pisa filas viejas del panel (p. ej. 平衡, 硬币, identity EN)
  /// con el mapa generado; si no, el CSV del API deja traducciones incorrectas.
  void ensureAppFallbacks() {
    _mergeMissing({
      'en': appFallbackEn,
      'es': appFallbackEs,
      'pt': appFallbackPt,
      'ar': appFallbackAr,
      'ru': appFallbackRu,
      'uk': appFallbackUk,
      'zh': appFallbackZh,
    }, english: appFallbackEn, overwrite: true);
  }

  /// Claves nuevas del LIVE aunque el CSV del servidor aún no las tenga.
  void ensureLiveFallbacks() {
    _mergeMissing({
      'en': _liveEn,
      'es': _liveEs,
      'pt': _livePt,
      'ar': _liveAr,
      'ru': _liveRu,
      'uk': _liveUk,
      'zh': _liveZh,
    });
  }

  /// Claves de Tareas aunque el CSV del servidor aún no las tenga.
  void ensureTaskFallbacks() {
    _mergeMissing({
      'en': _taskEn,
      'es': _taskEs,
      'pt': _taskPt,
      'ar': _taskEn,
      'ru': _taskEn,
      'uk': _taskEn,
      'zh': _taskEn,
    });
  }

  void ensureAgencyFallbacks() {
    _mergeMissing({
      'en': _agencyEn,
      'es': _agencyEs,
      'pt': _agencyPt,
      'ar': _agencyEn,
      'ru': _agencyEn,
      'uk': _agencyEn,
      'zh': _agencyEn,
    });
  }

  void ensureCallFallbacks() {
    _mergeMissing({
      'en': _callEn,
      'es': _callEs,
      'pt': _callPt,
      'ar': _callEn,
      'ru': _callEn,
      'uk': _callEn,
      'zh': _callEn,
    });
  }
}

const _liveEn = <String, String>{
  LKey.sayHello: 'Say Hello',
  LKey.sentAGift: 'sent a gift',
  LKey.arrivedInStyle: 'arrived in style',
  LKey.joinedTheLive: 'joined the LIVE',
  LKey.joinedShort: 'joined',
  LKey.isFollowingYou: 'is following you',
  LKey.sendMeGifts: 'Send me gifts!',
  LKey.giftMe: 'Gift me!',
  LKey.privateCall: 'Private',
  LKey.giftNotAvailable: 'Gift not available',
  LKey.insufficientCoins: 'Insufficient coins',
  LKey.invitesToPrivateCall: 'invites you to a private call',
  LKey.boostGifts: 'Boost gifts',
  LKey.inviteToCall: 'Invite to call',
  LKey.endBattle: 'End battle',
  LKey.battle: 'Battle',
  LKey.waitingBattleResponse: 'Waiting for battle response…',
  LKey.waitingForUser: 'Waiting for @name…',
  LKey.paused: 'PAUSED',
  LKey.liveStreamPausedHint: 'The host paused this LIVE. Please wait.',
  LKey.inCall: 'IN CALL',
  LKey.pkDraw: 'DRAW',
  LKey.pkResult: 'PK RESULT',
  LKey.pkWon: 'WON',
  LKey.pkLost: 'LOST',
  LKey.qualityLow: 'Low',
  LKey.qualityMedium: 'Medium',
  LKey.qualityHigh: 'High',
  LKey.seeGiftSenders: 'See who sent you gifts',
  LKey.noGiftsYet: 'No gifts yet',
  LKey.options: 'Options',
  LKey.later: 'Later',
  LKey.invitesYouToLive: 'invites you to their LIVE',
  LKey.continueAsGuest: 'Continue as Guest',
  LKey.joinToContinue: 'Link your account',
  LKey.joinToContinueDescription:
      'You can keep using the app as Guest. Link an email if you want to recover this account later.',
  LKey.joinNow: 'Link now',
  LKey.guestAccountExpires:
      'Guest accounts do not expire. Same privileges as a regular client.',
  LKey.coinWallet: 'Wallet',
  LKey.walletHistory: 'Wallet history',
  LKey.walletIncome: 'income',
  LKey.walletWithdrawLabel: 'withdraw',
  LKey.walletGiftFrom: 'Gift from @name',
  LKey.walletGiftLiveFrom: 'LIVE gift from @name',
  LKey.walletGiftChatFrom: 'Chat gift from @name',
  LKey.walletGiftCallFrom: 'Call gift from @name',
  LKey.walletPrivateCallWith: 'Private Call with @name',
  LKey.walletMatchWith: 'Match with @name',
  LKey.walletNoHistory: 'No movements',
  LKey.walletNoHistoryDesc:
      'Gifts from LIVE, chat and calls will appear here.',
  LKey.walletFilterAll: 'All',
  LKey.walletFilterLive: 'LIVE',
  LKey.walletFilterChat: 'Chat',
  LKey.walletFilterCalls: 'Calls',
  LKey.walletFilterGifts: 'Gifts',
  LKey.walletRechargeItem: 'Coin recharge',
  LKey.walletWithdrawItem: 'Withdrawal',
  LKey.walletExchangeRate: 'Exchange rate: @coins Coins = @currency1',
};

const _liveEs = <String, String>{
  LKey.sayHello: 'Di Hola',
  LKey.sentAGift: 'envió un regalo',
  LKey.arrivedInStyle: 'llegó con estilo',
  LKey.joinedTheLive: 'entró al LIVE',
  LKey.joinedShort: 'entró',
  LKey.isFollowingYou: 'te sigue',
  LKey.sendMeGifts: '¡Envíame regalos!',
  LKey.giftMe: '¡Regálame!',
  LKey.privateCall: 'Privado',
  LKey.giftNotAvailable: 'Regalo no disponible',
  LKey.insufficientCoins: 'Monedas insuficientes',
  LKey.invitesToPrivateCall: 'te invita a una llamada privada',
  LKey.boostGifts: 'Incentivar regalos',
  LKey.inviteToCall: 'Invitar a llamada',
  LKey.endBattle: 'Fin batalla',
  LKey.battle: 'Batalla',
  LKey.waitingBattleResponse: 'Esperando respuesta a la batalla…',
  LKey.waitingForUser: 'Esperando a @name…',
  LKey.paused: 'PAUSADO',
  LKey.liveStreamPausedHint: 'El host pausó este LIVE. Espera un momento.',
  LKey.inCall: 'EN LLAMADA',
  LKey.pkDraw: 'EMPATE',
  LKey.pkResult: 'RESULTADO PK',
  LKey.pkWon: 'GANÓ',
  LKey.pkLost: 'PERDIÓ',
  LKey.qualityLow: 'Baja',
  LKey.qualityMedium: 'Media',
  LKey.qualityHigh: 'Alta',
  LKey.seeGiftSenders: 'Ver quién te envió regalos',
  LKey.noGiftsYet: 'Aún no hay regalos',
  LKey.options: 'Opciones',
  LKey.later: 'Más tarde',
  LKey.invitesYouToLive: 'te invita a su LIVE',
  LKey.continueAsGuest: 'Continuar como invitado',
  LKey.joinToContinue: 'Vincular cuenta',
  LKey.joinToContinueDescription:
      'Puedes seguir usando la app como Guest. Vincula un email si quieres recuperar esta cuenta más adelante.',
  LKey.joinNow: 'Vincular ahora',
  LKey.guestAccountExpires:
      'Las cuentas Guest no caducan. Tienen los mismos privilegios que un cliente.',
  LKey.coinWallet: 'Monedero',
  LKey.walletHistory: 'Historial de monedero',
  LKey.walletIncome: 'ingresos',
  LKey.walletWithdrawLabel: 'retiros',
  LKey.walletGiftFrom: 'Regalo de @name',
  LKey.walletGiftLiveFrom: 'Regalo en LIVE de @name',
  LKey.walletGiftChatFrom: 'Regalo en chat de @name',
  LKey.walletGiftCallFrom: 'Regalo en llamada de @name',
  LKey.walletPrivateCallWith: 'Llamada privada con @name',
  LKey.walletMatchWith: 'Match con @name',
  LKey.walletNoHistory: 'Sin movimientos',
  LKey.walletNoHistoryDesc:
      'Aquí verás las monedas de LIVE, chat, llamadas y otros regalos.',
  LKey.walletFilterAll: 'Todos',
  LKey.walletFilterLive: 'LIVE',
  LKey.walletFilterChat: 'Chat',
  LKey.walletFilterCalls: 'Llamadas',
  LKey.walletFilterGifts: 'Regalos',
  LKey.walletRechargeItem: 'Recarga de monedas',
  LKey.walletWithdrawItem: 'Retiro',
  LKey.walletExchangeRate: 'Tasa de cambio: @coins Coins = @currency1',
};

const _livePt = <String, String>{
  LKey.sayHello: 'Diga olá',
  LKey.sentAGift: 'enviou um presente',
  LKey.arrivedInStyle: 'chegou com estilo',
  LKey.joinedTheLive: 'entrou no LIVE',
  LKey.joinedShort: 'entrou',
  LKey.isFollowingYou: 'está te seguindo',
  LKey.sendMeGifts: 'Envie-me presentes!',
  LKey.giftMe: 'Me presenteie!',
  LKey.privateCall: 'Privado',
  LKey.giftNotAvailable: 'Presente indisponível',
  LKey.insufficientCoins: 'Moedas insuficientes',
  LKey.invitesToPrivateCall: 'convida você para uma chamada privada',
  LKey.boostGifts: 'Incentivar presentes',
  LKey.inviteToCall: 'Convidar para chamada',
  LKey.endBattle: 'Encerrar batalha',
  LKey.battle: 'Batalha',
  LKey.waitingBattleResponse: 'Aguardando resposta da batalha…',
  LKey.waitingForUser: 'Aguardando @name…',
  LKey.paused: 'PAUSADO',
  LKey.liveStreamPausedHint: 'O host pausou este LIVE. Aguarde um momento.',
  LKey.inCall: 'EM CHAMADA',
  LKey.pkDraw: 'EMPATE',
  LKey.pkResult: 'RESULTADO PK',
  LKey.pkWon: 'VENCEU',
  LKey.pkLost: 'PERDEU',
  LKey.qualityLow: 'Baixa',
  LKey.qualityMedium: 'Média',
  LKey.qualityHigh: 'Alta',
  LKey.seeGiftSenders: 'Ver quem enviou presentes',
  LKey.noGiftsYet: 'Ainda não há presentes',
  LKey.options: 'Opções',
  LKey.later: 'Mais tarde',
  LKey.invitesYouToLive: 'convida você para o LIVE',
};

const _liveAr = <String, String>{
  LKey.sayHello: 'قل مرحبا',
  LKey.sentAGift: 'أرسل هدية',
  LKey.arrivedInStyle: 'وصل بأناقة',
  LKey.joinedTheLive: 'انضم إلى البث',
  LKey.joinedShort: 'انضم',
  LKey.isFollowingYou: 'يتابعك',
  LKey.sendMeGifts: 'أرسل لي هدايا!',
  LKey.giftMe: 'أهدني!',
  LKey.privateCall: 'خاص',
  LKey.giftNotAvailable: 'الهدية غير متاحة',
  LKey.insufficientCoins: 'عملات غير كافية',
  LKey.invitesToPrivateCall: 'يدعوك لمكالمة خاصة',
  LKey.boostGifts: 'حفّز الهدايا',
  LKey.inviteToCall: 'دعوة لمكالمة',
  LKey.endBattle: 'إنهاء المعركة',
  LKey.battle: 'معركة',
  LKey.waitingBattleResponse: 'بانتظار الرد على المعركة…',
  LKey.waitingForUser: 'بانتظار @name…',
  LKey.paused: 'متوقف',
  LKey.inCall: 'في مكالمة',
  LKey.pkDraw: 'تعادل',
  LKey.pkResult: 'نتيجة PK',
  LKey.pkWon: 'فاز',
  LKey.pkLost: 'خسر',
  LKey.qualityLow: 'منخفضة',
  LKey.qualityMedium: 'متوسطة',
  LKey.qualityHigh: 'عالية',
  LKey.seeGiftSenders: 'شاهد من أرسل لك هدايا',
  LKey.noGiftsYet: 'لا توجد هدايا بعد',
  LKey.options: 'خيارات',
  LKey.later: 'لاحقاً',
  LKey.invitesYouToLive: 'يدعوك إلى البث المباشر',
};

const _liveRu = <String, String>{
  LKey.sayHello: 'Скажи привет',
  LKey.sentAGift: 'отправил подарок',
  LKey.arrivedInStyle: 'прибыл со стилем',
  LKey.joinedTheLive: 'вошёл в эфир',
  LKey.joinedShort: 'вошёл',
  LKey.isFollowingYou: 'подписался на вас',
  LKey.sendMeGifts: 'Пришлите мне подарки!',
  LKey.giftMe: 'Подарите мне!',
  LKey.privateCall: 'Приват',
  LKey.giftNotAvailable: 'Подарок недоступен',
  LKey.insufficientCoins: 'Недостаточно монет',
  LKey.invitesToPrivateCall: 'приглашает на приватный звонок',
  LKey.boostGifts: 'Стимулировать подарки',
  LKey.inviteToCall: 'Пригласить на звонок',
  LKey.endBattle: 'Завершить битву',
  LKey.battle: 'Битва',
  LKey.waitingBattleResponse: 'Ожидание ответа на битву…',
  LKey.waitingForUser: 'Ожидание @name…',
  LKey.paused: 'ПАУЗА',
  LKey.inCall: 'НА ЗВОНКЕ',
  LKey.pkDraw: 'НИЧЬЯ',
  LKey.pkResult: 'ИТОГ PK',
  LKey.pkWon: 'ПОБЕДА',
  LKey.pkLost: 'ПОРАЖЕНИЕ',
  LKey.qualityLow: 'Низкое',
  LKey.qualityMedium: 'Среднее',
  LKey.qualityHigh: 'Высокое',
  LKey.seeGiftSenders: 'Кто отправил подарки',
  LKey.noGiftsYet: 'Подарков пока нет',
  LKey.options: 'Опции',
  LKey.later: 'Позже',
  LKey.invitesYouToLive: 'приглашает вас в эфир',
};

const _liveUk = <String, String>{
  LKey.sayHello: 'Скажи привіт',
  LKey.sentAGift: 'надіслав подарунок',
  LKey.arrivedInStyle: 'прибув зі стилем',
  LKey.joinedTheLive: 'приєднався до ефіру',
  LKey.joinedShort: 'приєднався',
  LKey.isFollowingYou: 'підписався на вас',
  LKey.sendMeGifts: 'Надішліть мені подарунки!',
  LKey.giftMe: 'Подаруйте мені!',
  LKey.privateCall: 'Приват',
  LKey.giftNotAvailable: 'Подарунок недоступний',
  LKey.insufficientCoins: 'Недостатньо монет',
  LKey.invitesToPrivateCall: 'запрошує на приватний дзвінок',
  LKey.boostGifts: 'Стимулювати подарунки',
  LKey.inviteToCall: 'Запросити на дзвінок',
  LKey.endBattle: 'Завершити битву',
  LKey.battle: 'Битва',
  LKey.waitingBattleResponse: 'Очікування відповіді на битву…',
  LKey.waitingForUser: 'Очікування @name…',
  LKey.paused: 'ПАУЗА',
  LKey.inCall: 'НА ДЗВІНКУ',
  LKey.pkDraw: 'НІЧИЯ',
  LKey.pkResult: 'ПІДСУМОК PK',
  LKey.pkWon: 'ПЕРЕМОГА',
  LKey.pkLost: 'ПОРАЗКА',
  LKey.qualityLow: 'Низька',
  LKey.qualityMedium: 'Середня',
  LKey.qualityHigh: 'Висока',
  LKey.seeGiftSenders: 'Хто надіслав подарунки',
  LKey.noGiftsYet: 'Подарунків ще немає',
  LKey.options: 'Опції',
  LKey.later: 'Пізніше',
  LKey.invitesYouToLive: 'запрошує вас в ефір',
};

const _liveZh = <String, String>{
  LKey.sayHello: '打个招呼',
  LKey.sentAGift: '送出了礼物',
  LKey.arrivedInStyle: '闪亮登场',
  LKey.joinedTheLive: '进入了直播',
  LKey.joinedShort: '加入',
  LKey.isFollowingYou: '关注了你',
  LKey.sendMeGifts: '送我礼物吧！',
  LKey.giftMe: '送我一个！',
  LKey.privateCall: '私密',
  LKey.giftNotAvailable: '礼物不可用',
  LKey.insufficientCoins: '金币不足',
  LKey.invitesToPrivateCall: '邀请你进行私密通话',
  LKey.boostGifts: '激励礼物',
  LKey.inviteToCall: '邀请通话',
  LKey.endBattle: '结束PK',
  LKey.battle: 'PK',
  LKey.waitingBattleResponse: '等待PK回应…',
  LKey.waitingForUser: '等待 @name…',
  LKey.paused: '已暂停',
  LKey.inCall: '通话中',
  LKey.pkDraw: '平局',
  LKey.pkResult: 'PK结果',
  LKey.pkWon: '胜',
  LKey.pkLost: '负',
  LKey.qualityLow: '低',
  LKey.qualityMedium: '中',
  LKey.qualityHigh: '高',
  LKey.seeGiftSenders: '查看送礼用户',
  LKey.noGiftsYet: '还没有礼物',
  LKey.options: '选项',
  LKey.later: '稍后',
  LKey.invitesYouToLive: '邀请你进入直播',
};

const _taskEn = <String, String>{
  LKey.tasksEndToday: "Today's tasks end in",
  LKey.liveMinutesLabel: 'LIVE time',
  LKey.taskCoinsLabel: 'Coins',
  LKey.goDoTask: 'Go',
  LKey.goToLiveCategory: 'Go LIVE',
  LKey.goToMatchCategory: 'Go to Match',
  LKey.goToChatCategory: 'Go to Chat',
  LKey.goToProfileCategory: 'Go to Profile',
  LKey.goToExploreCategory: 'Go to Explore',
  LKey.goToFeedCategory: 'Create post',
  LKey.nextTaskUnlocked: 'Next task unlocked',
  LKey.completeFirstTaskToContinue: 'Complete task 1 to go to this category',
  LKey.claim: 'Claim',
  LKey.claimed: 'Claimed',
};

const _taskEs = <String, String>{
  LKey.tasksEndToday: 'Las tareas de hoy terminan en',
  LKey.liveMinutesLabel: 'Tiempo LIVE',
  LKey.taskCoinsLabel: 'Coins',
  LKey.goDoTask: 'Ir',
  LKey.goToLiveCategory: 'Ir a LIVE',
  LKey.goToMatchCategory: 'Ir a Match',
  LKey.goToChatCategory: 'Ir a Chat',
  LKey.goToProfileCategory: 'Ir a Perfil',
  LKey.goToExploreCategory: 'Ir a Explorar',
  LKey.goToFeedCategory: 'Crear publicación',
  LKey.nextTaskUnlocked: 'Siguiente tarea desbloqueada',
  LKey.completeFirstTaskToContinue:
      'Completa la Tarea 1 para ir a esta categoría',
  LKey.claim: 'Reclamar',
  LKey.claimed: 'Reclamado',
};

const _taskPt = <String, String>{
  LKey.tasksEndToday: 'As tarefas de hoje terminam em',
  LKey.liveMinutesLabel: 'Tempo LIVE',
  LKey.taskCoinsLabel: 'Coins',
  LKey.goDoTask: 'Ir',
  LKey.goToLiveCategory: 'Ir ao LIVE',
  LKey.goToMatchCategory: 'Ir ao Match',
  LKey.goToChatCategory: 'Ir ao Chat',
  LKey.goToProfileCategory: 'Ir ao Perfil',
  LKey.goToExploreCategory: 'Ir a Explorar',
  LKey.goToFeedCategory: 'Criar publicação',
  LKey.nextTaskUnlocked: 'Próxima tarefa desbloqueada',
  LKey.completeFirstTaskToContinue:
      'Conclua a Tarefa 1 para ir a esta categoria',
  LKey.claim: 'Resgatar',
  LKey.claimed: 'Resgatado',
};

const _agencyEn = <String, String>{
  LKey.newFollowers: 'New Followers',
  LKey.walletAgencyShareFrom: 'Agency share from @name',
  LKey.agencyStreamers: 'Streamers',
  LKey.agencyDashboardTitle: 'Agency',
  LKey.agencyYourStreamers: 'Your affiliated streamers',
  LKey.agencyNoStreamers: "You don't have streamers yet",
  LKey.agencyCreateStreamerHint:
      'Create a Streamer account affiliated to your agency.',
  LKey.agencyCreateStreamer: 'Create streamer',
  LKey.agencyStreamerEarned: 'Streamer earned',
  LKey.agencyYourShare: 'Your share',
  LKey.agencyToday: 'Today',
  LKey.agencyWeek: 'This week',
  LKey.agencyMonth: 'This month',
  LKey.agencyLifetime: 'Total',
  LKey.agencyWalletHint: '10% of the App margin from your streamers',
};

const _agencyEs = <String, String>{
  LKey.newFollowers: 'Nuevos seguidores',
  LKey.walletAgencyShareFrom: 'Comisión de @name',
  LKey.agencyStreamers: 'Streamers',
  LKey.agencyDashboardTitle: 'Agencia',
  LKey.agencyYourStreamers: 'Tus streamers afiliados',
  LKey.agencyNoStreamers: 'Aún no tienes streamers',
  LKey.agencyCreateStreamerHint:
      'Crea una cuenta Streamer afiliada a tu agencia.',
  LKey.agencyCreateStreamer: 'Crear streamer',
  LKey.agencyStreamerEarned: 'Ganó el streamer',
  LKey.agencyYourShare: 'Tu comisión',
  LKey.agencyToday: 'Hoy',
  LKey.agencyWeek: 'Esta semana',
  LKey.agencyMonth: 'Este mes',
  LKey.agencyLifetime: 'Total',
  LKey.agencyWalletHint: '10% del margen App de tus streamers',
};

const _agencyPt = <String, String>{
  LKey.newFollowers: 'Novos seguidores',
  LKey.walletAgencyShareFrom: 'Comissão de @name',
  LKey.agencyStreamers: 'Streamers',
  LKey.agencyDashboardTitle: 'Agência',
  LKey.agencyYourStreamers: 'Seus streamers afiliados',
  LKey.agencyNoStreamers: 'Você ainda não tem streamers',
  LKey.agencyCreateStreamerHint:
      'Crie uma conta Streamer afiliada à sua agência.',
  LKey.agencyCreateStreamer: 'Criar streamer',
  LKey.agencyStreamerEarned: 'O streamer ganhou',
  LKey.agencyYourShare: 'Sua comissão',
  LKey.agencyToday: 'Hoje',
  LKey.agencyWeek: 'Esta semana',
  LKey.agencyMonth: 'Este mês',
  LKey.agencyLifetime: 'Total',
  LKey.agencyWalletHint: '10% da margem App dos seus streamers',
};

const _callEn = <String, String>{
  LKey.callStreamerInCall: 'This streamer is already in a call',
  LKey.callStreamerOffline: 'This streamer is offline',
  LKey.onlineNow: 'Online',
  LKey.callOnlyFromLive: 'Join the LIVE to call this streamer',
  LKey.joinThisLive: 'Join LIVE',
  LKey.callEndedInsufficientCoins: 'Not enough coins to continue the call',
  LKey.callEndedClientNoCoins: 'The call ended: the client ran out of coins',
  LKey.liveBadge: 'LIVE',
  LKey.peopleWatching: '@count watching',
  LKey.lastCallMinutesAgo: 'LAST CALL @min MIN AGO',
  LKey.lastCallHoursAgo: 'LAST CALL @hours H AGO',
  LKey.impression: 'Impression',
  LKey.rankLabel: 'Rank: @grade',
  LKey.rateImpression: 'Rate',
  LKey.saveRating: 'Save',
  LKey.herTraits: 'How she defines herself',
  LKey.otherTraits: 'More traits',
  LKey.maxTraitsHint: 'Choose up to @count',
  LKey.ratingSaved: 'Thanks for rating',
  LKey.offlineBadge: 'Off',
  LKey.wompiLocalChargeHint:
      'The charge will be processed in local currency (COP) at the current exchange rate equivalent to \$@amount USD.',
  LKey.continueToPayment: 'Continue to payment',
};

const _callEs = <String, String>{
  LKey.callStreamerInCall: 'Esta streamer está en una llamada',
  LKey.callStreamerOffline: 'Esta streamer está desconectada',
  LKey.onlineNow: 'En línea',
  LKey.callOnlyFromLive: 'Entra al LIVE para llamarla',
  LKey.joinThisLive: 'Unirse al LIVE',
  LKey.callEndedInsufficientCoins:
      'No tienes coins suficientes para continuar la llamada',
  LKey.callEndedClientNoCoins:
      'La llamada terminó: el cliente no tiene coins',
  LKey.liveBadge: 'En vivo',
  LKey.peopleWatching: '@count personas viendo',
  LKey.lastCallMinutesAgo: 'ULTIMA LLAMADA HACE @min MIN',
  LKey.lastCallHoursAgo: 'ULTIMA LLAMADA HACE @hours H',
  LKey.impression: 'Impresión',
  LKey.rankLabel: 'Rango: @grade',
  LKey.rateImpression: 'Calificar',
  LKey.saveRating: 'Guardar',
  LKey.herTraits: 'Así se define',
  LKey.otherTraits: 'Más cualidades',
  LKey.maxTraitsHint: 'Elige hasta @count',
  LKey.ratingSaved: 'Gracias por calificar',
  LKey.offlineBadge: 'Off',
  LKey.wompiLocalChargeHint:
      'El cobro se procesará en moneda local (COP) según la tasa de cambio actual equivalente a \$@amount USD.',
  LKey.continueToPayment: 'Continuar al pago',
};

const _callPt = <String, String>{
  LKey.callStreamerInCall: 'Esta streamer já está em uma chamada',
  LKey.callStreamerOffline: 'Esta streamer está offline',
  LKey.onlineNow: 'Online',
  LKey.callOnlyFromLive: 'Entre no LIVE para ligar',
  LKey.joinThisLive: 'Entrar no LIVE',
  LKey.callEndedInsufficientCoins:
      'Você não tem coins suficientes para continuar a chamada',
  LKey.callEndedClientNoCoins:
      'A chamada terminou: o cliente ficou sem coins',
  LKey.liveBadge: 'Ao vivo',
  LKey.peopleWatching: '@count assistindo',
  LKey.lastCallMinutesAgo: 'ÚLTIMA CHAMADA HÁ @min MIN',
  LKey.lastCallHoursAgo: 'ÚLTIMA CHAMADA HÁ @hours H',
  LKey.impression: 'Impressão',
  LKey.rankLabel: 'Rank: @grade',
  LKey.rateImpression: 'Avaliar',
  LKey.saveRating: 'Salvar',
  LKey.herTraits: 'Como ela se define',
  LKey.otherTraits: 'Mais qualidades',
  LKey.maxTraitsHint: 'Escolha até @count',
  LKey.ratingSaved: 'Obrigado por avaliar',
  LKey.offlineBadge: 'Off',
  LKey.wompiLocalChargeHint:
      'A cobrança será processada em moeda local (COP) conforme a taxa de câmbio atual equivalente a \$@amount USD.',
  LKey.continueToPayment: 'Continuar para o pagamento',
};
