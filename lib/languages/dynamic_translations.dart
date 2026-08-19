import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';

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
      if (_keys.containsKey(lang)) {
        _keys[lang]?.addAll(translations);
      } else {
        _keys[lang] = Map<String, String>.from(translations);
      }
    });
    Get.appendTranslations(map);
    ensureLiveFallbacks();
    ensureTaskFallbacks();
  }

  /// Claves nuevas del LIVE aunque el CSV del servidor aún no las tenga.
  void ensureLiveFallbacks() {
    final fallbacks = <String, Map<String, String>>{
      'en': _liveEn,
      'es': _liveEs,
      'pt': _livePt,
      'ar': _liveAr,
      'ru': _liveRu,
      'uk': _liveUk,
      'zh': _liveZh,
    };
    final toAppend = <String, Map<String, String>>{};
    fallbacks.forEach((lang, map) {
      final existing = _keys[lang] ?? const <String, String>{};
      final missing = <String, String>{};
      map.forEach((k, v) {
        if (!existing.containsKey(k)) missing[k] = v;
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

  /// Claves de Tareas aunque el CSV del servidor aún no las tenga.
  void ensureTaskFallbacks() {
    final fallbacks = <String, Map<String, String>>{
      'en': _taskEn,
      'es': _taskEs,
      'pt': _taskPt,
      'ar': _taskEn,
      'ru': _taskEn,
      'uk': _taskEn,
      'zh': _taskEn,
    };
    final toAppend = <String, Map<String, String>>{};
    fallbacks.forEach((lang, map) {
      final existing = _keys[lang] ?? const <String, String>{};
      final missing = <String, String>{};
      map.forEach((k, v) {
        if (!existing.containsKey(k)) missing[k] = v;
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
  LKey.joinToContinue: 'Join to continue',
  LKey.joinToContinueDescription:
      'Create an account to match, send messages, make calls, comment and send gifts.',
  LKey.joinNow: 'Join now',
  LKey.guestAccountExpires: 'Guest accounts expire in 7 days.',
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
  LKey.joinToContinue: 'Únete para continuar',
  LKey.joinToContinueDescription:
      'Crea una cuenta para hacer match, enviar mensajes, llamar, comentar y enviar regalos.',
  LKey.joinNow: 'Unirme ahora',
  LKey.guestAccountExpires: 'Las cuentas de invitado caducan en 7 días.',
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
