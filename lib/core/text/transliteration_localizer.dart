String localizedTransliteration(String source, String languageCode) {
  final normalizedLanguage = languageCode.trim().toLowerCase();
  final normalizedSource = _normalizeTransliterationKey(source);

  if (normalizedLanguage == 'ru') {
    return _ruTransliterationBySource[normalizedSource] ?? source;
  }

  // Для EN (и любого другого языка кроме RU) — нормализуем старые слитные
  // формы в новые с дефисами. Если форма уже новая — возвращаем как есть.
  return _enTransliterationBySource[normalizedSource] ?? source;
}

String _normalizeTransliterationKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('`', "'")
      .replaceAll(RegExp(r'\s+'), ' ');
}

final Map<String, String> _ruTransliterationBySource = {
  // === Шаги намазов (новый профессиональный формат с дефисами) ===
  _normalizeTransliterationKey('Allahu akbar'): 'Аллаху акбар',
  _normalizeTransliterationKey('Amin'): 'Амин',
  _normalizeTransliterationKey("A'udhu bi-llahi mina-sh-shaytani-r-rajim"):
      "А'узу би-Лляхи мин аш-шайтанир-раджим",
  _normalizeTransliterationKey('Rabba-na wa la-ka-l-hamd'):
      'Рабба-на ва ля-ка ль-хамд',
  _normalizeTransliterationKey('Rabbi-ghfir-li'): 'Рабби гфир-ли',
  _normalizeTransliterationKey("Sami'a-llahu li-man hamidah"):
      "Сами'а Ллаху ли-ман хамидах",
  _normalizeTransliterationKey("Subhana Rabbiya-l-A'la"):
      "Субхана Раббийа ль-А'ля",
  _normalizeTransliterationKey("Subhana Rabbiya-l-'Azim"):
      "Субхана Раббийа ль-'Азым",
  _normalizeTransliterationKey("As-salamu 'alay-kum wa rahmatu-llah"):
      "Ас-саляму 'алейкум ва рахмату Ллах",
  _normalizeTransliterationKey('Bismillah'): 'Би-сми Ллях',

  // === Аль-Фатиха ===
  _normalizeTransliterationKey('Bi-smi-llahi-r-Rahmani-r-Rahim'):
      'Би-сми Лляхи р-Рахмани р-Рахим',
  _normalizeTransliterationKey("Al-hamdu li-llahi Rabbi-l-'alamin"):
      "Аль-хамду ли-Лляхи рабби ль-'алямин",
  _normalizeTransliterationKey('Ar-Rahmani-r-Rahim'): 'Ар-Рахмани р-Рахим',
  _normalizeTransliterationKey('Maliki yawmi-d-din'): 'Малики йауми д-дин',
  _normalizeTransliterationKey("Iyya-ka na'budu wa iyya-ka nasta'in"):
      "Иййяка на'буду ва иййяка наста'ин",
  _normalizeTransliterationKey('Ihdi-na-s-sirata-l-mustaqim'):
      'Ихди-на с-сырата ль-мустакым',
  _normalizeTransliterationKey(
        "Sirata-lladhina an'amta 'alay-him, ghayri-l-maghdubi 'alay-him wa la-d-dallin",
      ):
      "Сырат аллязина ан'амта 'алей-хим гайриль-магдуби 'алей-хим ва ля д-даллин",

  // === Аль-Ихляс ===
  _normalizeTransliterationKey('Qul Huwa-llahu Ahad'): 'Куль хува Ллаху ахад',
  _normalizeTransliterationKey('Allahu-s-Samad'): 'Аллаху с-самад',
  _normalizeTransliterationKey('Lam yalid wa lam yulad'):
      'Лям йалид ва лям йуляд',
  _normalizeTransliterationKey('Wa lam yakun la-hu kufuwan ahad'):
      'Ва лям йакун ля-ху куфуван ахад',

  // === Аль-Фаляк ===
  _normalizeTransliterationKey("Qul a'udhu bi-Rabbi-l-falaq"):
      "Куль а'узу би-рабби ль-фаляк",
  _normalizeTransliterationKey('Min sharri ma khalaq'): 'Мин шарри ма халяк',
  _normalizeTransliterationKey('Wa min sharri ghasiqin idha waqab'):
      "Ва мин шарри г'асикын иза вакаб",
  _normalizeTransliterationKey("Wa min sharri-n-naffathati fi-l-'uqad"):
      "Ва мин шарри н-наффасати фи-ль-'укад",
  _normalizeTransliterationKey('Wa min sharri hasidin idha hasad'):
      'Ва мин шарри хасидин иза хасад',

  // === Ан-Нас ===
  _normalizeTransliterationKey("Qul a'udhu bi-Rabbi-n-nas"):
      "Куль а'узу би рабби н-нас",
  _normalizeTransliterationKey('Maliki-n-nas'): 'Малики н-нас',
  _normalizeTransliterationKey('Ilahi-n-nas'): 'Иляхи н-нас',
  _normalizeTransliterationKey('Min sharri-l-waswasi-l-khannas'):
      'Мин шарри ль-васваси ль-ханнас',
  _normalizeTransliterationKey('Alladhi yuwaswisu fi suduri-n-nas'):
      'Аллязи йувасвису фи судури н-нас',
  _normalizeTransliterationKey('Mina-l-jinnati wa-n-nas'):
      'Мин аль-джиннати ва-н-нас',

  // === Ат-Тахият ===
  _normalizeTransliterationKey(
        'At-tahiyyatu li-llahi wa-s-salawatu wa-t-tayyibat',
      ):
      'Ат-тахиййату ли-Лляхи ва-с-салявату ва-т-таййибату',
  _normalizeTransliterationKey(
        "As-salamu 'alay-ka ayyuha-n-nabiyyu wa rahmatu-llahi wa barakatu-h",
      ):
      "Ас-саляму 'алейка аййуха н-набиййу ва рахмату Ллахи ва баракяту-ху",
  _normalizeTransliterationKey(
        "As-salamu 'alay-na wa 'ala 'ibadi-llahi-s-salihin",
      ):
      "Ас-саляму 'алей-на ва 'аля 'ибади Лляхис-салихина",
  _normalizeTransliterationKey(
        "Ash-hadu an la ilaha illa-llah, wa ash-hadu anna Muhammadan 'abdu-hu wa rasulu-h",
      ):
      "Ашхаду ан ля иляха илля Ллаху ва ашхаду анна Мухаммадан 'абду-ху ва расулю-ху",

  // === Салават ===
  _normalizeTransliterationKey(
        "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad",
      ):
      "Аллахумма салли 'аля Мухаммадин ва 'аля али Мухаммадин",
  _normalizeTransliterationKey(
        "Ka-ma sallay-ta 'ala Ibrahima wa 'ala ali Ibrahim",
      ):
      "Кя-ма саллейта 'аля Ибрахима ва 'аля али Ибрахима",
  _normalizeTransliterationKey('Inna-ka Hamidun Majid'):
      'Инна-ка Хамидун Маджидун',
  _normalizeTransliterationKey(
        "Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad",
      ):
      "Аллахумма барик 'аля Мухаммадин ва 'аля али Мухаммадин",
  _normalizeTransliterationKey(
        "Ka-ma barak-ta 'ala Ibrahima wa 'ala ali Ibrahim",
      ):
      "Кя-ма баракта 'аля Ибрахима ва 'аля али Ибрахима",

  // === Уже на русском — оставляем как есть ===
  _normalizeTransliterationKey("А'узу билляхи минаш-шайтанир-раджим"):
      "А'узу би-Лляхи мин аш-шайтанир-раджим",
  _normalizeTransliterationKey('Аллаху акбар'): 'Аллаху акбар',

  // === Backwards-compatibility (старые ключи на случай кэшированных данных) ===
  _normalizeTransliterationKey("A'oothu billaahi minash-shaytanir-rajeem"):
      "А'узу би-Лляхи мин аш-шайтанир-раджим",
  _normalizeTransliterationKey('Ameen'): 'Амин',
  _normalizeTransliterationKey('Allahus samad'): 'Аллаху с-самад',
  _normalizeTransliterationKey('Bismillahir rahmanir rahim'):
      'Би-сми Лляхи р-Рахмани р-Рахим',
  _normalizeTransliterationKey("Al hamdu lillahi rabbil 'alamin"):
      "Аль-хамду ли-Лляхи рабби ль-'алямин",
  _normalizeTransliterationKey('Arrahmanir rahim'): 'Ар-Рахмани р-Рахим',
  _normalizeTransliterationKey('Maliki yawmiddin'): 'Малики йауми д-дин',
  _normalizeTransliterationKey('Ihdinas siratal mustaqim'):
      'Ихди-на с-сырата ль-мустакым',
  _normalizeTransliterationKey(
        "Siratal ladhina an'amta alaihim ghairil maghdubi alaihim wa lad dallin",
      ):
      "Сырат аллязина ан'амта 'алей-хим гайриль-магдуби 'алей-хим ва ля д-даллин",
  _normalizeTransliterationKey('Qul hu wal lahu ahad'): 'Куль хува Ллаху ахад',
  _normalizeTransliterationKey('Lam Yalid Wa Lam Yulad'):
      'Лям йалид ва лям йуляд',
  _normalizeTransliterationKey('Lam Yalid Wa Lam Yūlad'):
      'Лям йалид ва лям йуляд',
  _normalizeTransliterationKey('Wa lam yakul lahu kufuwan ahad'):
      'Ва лям йакун ля-ху куфуван ахад',
  _normalizeTransliterationKey('Wa lam ya kul lahu kufuwan ahad'):
      'Ва лям йакун ля-ху куфуван ахад',
  _normalizeTransliterationKey("Qul a'oothu birabbil falaq"):
      "Куль а'узу би-рабби ль-фаляк",
  _normalizeTransliterationKey("QuI a'oothu birabbil falaq"):
      "Куль а'узу би-рабби ль-фаляк",
  _normalizeTransliterationKey('Min sharri maa khalaq'): 'Мин шарри ма халяк',
  _normalizeTransliterationKey('Wamin sharri ghasiqin ithaa waqab'):
      "Ва мин шарри г'асикын иза вакаб",
  _normalizeTransliterationKey("Wamin sharrin-naffaathaati fil'uqad"):
      "Ва мин шарри н-наффасати фи-ль-'укад",
  _normalizeTransliterationKey('Wamin sharri haasidin ithaa hasad'):
      'Ва мин шарри хасидин иза хасад',
  _normalizeTransliterationKey("Qul a'oothu birabbinnas"):
      "Куль а'узу би рабби н-нас",
  _normalizeTransliterationKey("QuI a'oothu birabbinnas"):
      "Куль а'узу би рабби н-нас",
  _normalizeTransliterationKey('Malikinnas'): 'Малики н-нас',
  _normalizeTransliterationKey('Ilaahinnas'): 'Иляхи н-нас',
  _normalizeTransliterationKey('Min sharril waswaasil khannaas'):
      'Мин шарри ль-васваси ль-ханнас',
  _normalizeTransliterationKey('Allathee yuwaswisu fee sudoorinnaas'):
      'Аллязи йувасвису фи судури н-нас',
  _normalizeTransliterationKey('Minal jinnati wannas'):
      'Мин аль-джиннати ва-н-нас',
  _normalizeTransliterationKey(
        'Attahiyyaatu lilaahi wassalawaatu wattayyibaatu',
      ):
      'Ат-тахиййату ли-Лляхи ва-с-салявату ва-т-таййибату',
  _normalizeTransliterationKey(
        "Assalaamu 'alayka ay-yuhan-nabiyyu wa rahmatullaahi wabarakaatuh",
      ):
      "Ас-саляму 'алейка аййуха н-набиййу ва рахмату Ллахи ва баракяту-ху",
  _normalizeTransliterationKey("Assalaamu 'alaykum wa rahmatullah"):
      "Ас-саляму 'алейкум ва рахмату Ллах",
  _normalizeTransliterationKey(
        "Assalaamu'alaynaa wa'alaa'ibaadillaahissaliheen",
      ):
      "Ас-саляму 'алей-на ва 'аля 'ибади Лляхис-салихина",
  _normalizeTransliterationKey(
        "Ash-hadu allaa ilaaha illallaah wa ash-hadu anna Muhammadan 'abduhu wa rasooluh",
      ):
      "Ашхаду ан ля иляха илля Ллаху ва ашхаду анна Мухаммадан 'абду-ху ва расулю-ху",
  _normalizeTransliterationKey(
        "Allahumma salli 'ala Muhammad wa 'ala aali Muhammad",
      ):
      "Аллахумма салли 'аля Мухаммадин ва 'аля али Мухаммадин",
  _normalizeTransliterationKey(
        "Kamaa salyta 'ala Ibraheem wa 'ala aali Ibraheem",
      ):
      "Кя-ма саллейта 'аля Ибрахима ва 'аля али Ибрахима",
  _normalizeTransliterationKey('Innaka hameedun Majeed'):
      'Инна-ка Хамидун Маджидун',
  _normalizeTransliterationKey(
        "Wa baarik 'alaa Muhammad wa 'alaa aali Muhammad",
      ):
      "Аллахумма барик 'аля Мухаммадин ва 'аля али Мухаммадин",
  _normalizeTransliterationKey(
        "Kamaa baarakta 'alaa Ibraheem wa 'alaa aali Ibraheem",
      ):
      "Кя-ма баракта 'аля Ибрахима ва 'аля али Ибрахима",
  _normalizeTransliterationKey('Subhanaka Allahumma'): 'Субхана-кя, Аллахумма',
  _normalizeTransliterationKey(
        "Subhanaka Allahumma wa bi-hamdika, wa tabaraka-smuka, wa ta'ala jadduka, wa la ilaha ghayruk",
      ):
      "Субхана-кя, Аллахумма, ва би-хамди-кя, ва табаракя исму-кя ва та аля джадду-кя ва ля иляха гайру-кя",
  _normalizeTransliterationKey('Rabbanaa wa lakal hamd'):
      'Рабба-на ва ля-ка ль-хамд',
  _normalizeTransliterationKey('Rabbighfirlee'): 'Рабби гфир-ли',
  _normalizeTransliterationKey("Sami'-Allaahu liman hamidah"):
      "Сами'а Ллаху ли-ман хамидах",
  _normalizeTransliterationKey("Subhaana rabbiyal 'alaa"):
      "Субхана Раббийа ль-А'ля",
  _normalizeTransliterationKey("Subhaana rabbiyal 'atheem"):
      "Субхана Раббийа ль-'Азым",
};

/// EN-форма: нормализуем старые слитные транслитерации в новые формы
/// с дефисами. Если транслитерация в данных уже новая — она не попадёт
/// в эту карту, и localizer вернёт source как есть.
final Map<String, String> _enTransliterationBySource = {
  // Шаги намазов
  _normalizeTransliterationKey("A'oothu billaahi minash-shaytanir-rajeem"):
      "A'udhu bi-llahi mina-sh-shaytani-r-rajim",
  _normalizeTransliterationKey('Ameen'): 'Amin',
  _normalizeTransliterationKey('Rabbanaa wa lakal hamd'):
      'Rabba-na wa la-ka-l-hamd',
  _normalizeTransliterationKey('Rabbighfirlee'): 'Rabbi-ghfir-li',
  _normalizeTransliterationKey("Sami'-Allaahu liman hamidah"):
      "Sami'a-llahu li-man hamidah",
  _normalizeTransliterationKey("Subhaana rabbiyal 'alaa"):
      "Subhana Rabbiya-l-A'la",
  _normalizeTransliterationKey("Subhaana rabbiyal 'atheem"):
      "Subhana Rabbiya-l-'Azim",
  _normalizeTransliterationKey("Assalaamu 'alaykum wa rahmatullah"):
      "As-salamu 'alay-kum wa rahmatu-llah",

  // Аль-Фатиха
  _normalizeTransliterationKey('Bismillahir rahmanir rahim'):
      'Bi-smi-llahi-r-Rahmani-r-Rahim',
  _normalizeTransliterationKey("Al hamdu lillahi rabbil 'alamin"):
      "Al-hamdu li-llahi Rabbi-l-'alamin",
  _normalizeTransliterationKey('Arrahmanir rahim'): 'Ar-Rahmani-r-Rahim',
  _normalizeTransliterationKey('Maliki yawmiddin'): 'Maliki yawmi-d-din',
  _normalizeTransliterationKey('Ihdinas siratal mustaqim'):
      'Ihdi-na-s-sirata-l-mustaqim',
  _normalizeTransliterationKey(
        "Siratal ladhina an'amta alaihim ghairil maghdubi alaihim wa lad dallin",
      ):
      "Sirata-lladhina an'amta 'alay-him, ghayri-l-maghdubi 'alay-him wa la-d-dallin",

  // Аль-Ихляс
  _normalizeTransliterationKey('Qul hu wal lahu ahad'): 'Qul Huwa-llahu Ahad',
  _normalizeTransliterationKey('Allahus samad'): 'Allahu-s-Samad',
  _normalizeTransliterationKey('Lam Yalid Wa Lam Yulad'):
      'Lam yalid wa lam yulad',
  _normalizeTransliterationKey('Lam Yalid Wa Lam Yūlad'):
      'Lam yalid wa lam yulad',
  _normalizeTransliterationKey('Wa lam yakul lahu kufuwan ahad'):
      'Wa lam yakun la-hu kufuwan ahad',
  _normalizeTransliterationKey('Wa lam ya kul lahu kufuwan ahad'):
      'Wa lam yakun la-hu kufuwan ahad',

  // Аль-Фаляк
  _normalizeTransliterationKey("Qul a'oothu birabbil falaq"):
      "Qul a'udhu bi-Rabbi-l-falaq",
  _normalizeTransliterationKey("QuI a'oothu birabbil falaq"):
      "Qul a'udhu bi-Rabbi-l-falaq",
  _normalizeTransliterationKey('Min sharri maa khalaq'):
      'Min sharri ma khalaq',
  _normalizeTransliterationKey('Wamin sharri ghasiqin ithaa waqab'):
      'Wa min sharri ghasiqin idha waqab',
  _normalizeTransliterationKey("Wamin sharrin-naffaathaati fil'uqad"):
      "Wa min sharri-n-naffathati fi-l-'uqad",
  _normalizeTransliterationKey('Wamin sharri haasidin ithaa hasad'):
      'Wa min sharri hasidin idha hasad',

  // Ан-Нас
  _normalizeTransliterationKey("Qul a'oothu birabbinnas"):
      "Qul a'udhu bi-Rabbi-n-nas",
  _normalizeTransliterationKey("QuI a'oothu birabbinnas"):
      "Qul a'udhu bi-Rabbi-n-nas",
  _normalizeTransliterationKey('Malikinnas'): 'Maliki-n-nas',
  _normalizeTransliterationKey('Ilaahinnas'): 'Ilahi-n-nas',
  _normalizeTransliterationKey('Min sharril waswaasil khannaas'):
      'Min sharri-l-waswasi-l-khannas',
  _normalizeTransliterationKey('Allathee yuwaswisu fee sudoorinnaas'):
      'Alladhi yuwaswisu fi suduri-n-nas',
  _normalizeTransliterationKey('Minal jinnati wannas'):
      'Mina-l-jinnati wa-n-nas',

  // Ат-Тахият
  _normalizeTransliterationKey(
        'Attahiyyaatu lilaahi wassalawaatu wattayyibaatu',
      ):
      'At-tahiyyatu li-llahi wa-s-salawatu wa-t-tayyibat',
  _normalizeTransliterationKey(
        "Assalaamu 'alayka ay-yuhan-nabiyyu wa rahmatullaahi wabarakaatuh",
      ):
      "As-salamu 'alay-ka ayyuha-n-nabiyyu wa rahmatu-llahi wa barakatu-h",
  _normalizeTransliterationKey(
        "Assalaamu'alaynaa wa'alaa'ibaadillaahissaliheen",
      ):
      "As-salamu 'alay-na wa 'ala 'ibadi-llahi-s-salihin",
  _normalizeTransliterationKey(
        "Ash-hadu allaa ilaaha illallaah wa ash-hadu anna Muhammadan 'abduhu wa rasooluh",
      ):
      "Ash-hadu an la ilaha illa-llah, wa ash-hadu anna Muhammadan 'abdu-hu wa rasulu-h",

  // Салават
  _normalizeTransliterationKey(
        "Allahumma salli 'ala Muhammad wa 'ala aali Muhammad",
      ):
      "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad",
  _normalizeTransliterationKey(
        "Kamaa salyta 'ala Ibraheem wa 'ala aali Ibraheem",
      ):
      "Ka-ma sallay-ta 'ala Ibrahima wa 'ala ali Ibrahim",
  _normalizeTransliterationKey('Innaka hameedun Majeed'):
      'Inna-ka Hamidun Majid',
  _normalizeTransliterationKey(
        "Wa baarik 'alaa Muhammad wa 'alaa aali Muhammad",
      ):
      "Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad",
  _normalizeTransliterationKey(
        "Kamaa baarakta 'alaa Ibraheem wa 'alaa aali Ibraheem",
      ):
      "Ka-ma barak-ta 'ala Ibrahima wa 'ala ali Ibrahim",
};
