String localizedTransliteration(String source, String languageCode) {
  final normalizedLanguage = languageCode.trim().toLowerCase();
  if (normalizedLanguage != 'ru') {
    return source;
  }

  final normalizedSource = _normalizeTransliterationKey(source);
  return _ruTransliterationBySource[normalizedSource] ?? source;
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
  _normalizeTransliterationKey("A'oothu billaahi minash-shaytanir-rajeem"):
      "А'узу билляхи минаш-шайтанир-раджим",
  _normalizeTransliterationKey("Al hamdu lillahi rabbil 'alamin"):
      "Аль-хамду лилляхи раббиль-'алямин",
  _normalizeTransliterationKey('Allahu akbar'): 'Аллаху акбар',
  _normalizeTransliterationKey(
        "Allahumma salli 'ala Muhammad wa 'ala aali Muhammad",
      ):
      "Аллахумма салли 'аля Мухаммадин ва 'аля али Мухаммад",
  _normalizeTransliterationKey('Allahus samad'): 'Аллахус-самад',
  _normalizeTransliterationKey('Allathee yuwaswisu fee sudoorinnaas'):
      'Аллязи ювасвису фи судурин-нас',
  _normalizeTransliterationKey('Ameen'): 'Амин',
  _normalizeTransliterationKey('Arrahmanir rahim'): 'Ар-рахманир-рахим',
  _normalizeTransliterationKey(
        "Ash-hadu allaa ilaaha illallaah wa ash-hadu anna Muhammadan 'abduhu wa rasooluh",
      ):
      "Аш-хаду алля иляха илляллах ва аш-хаду анна Мухаммадан 'абдуху ва расулюх",
  _normalizeTransliterationKey(
        "Assalaamu 'alayka ay-yuhan-nabiyyu wa rahmatullaahi wabarakaatuh",
      ):
      "Ас-саляму 'аляйка айюхан-набийю ва рахматуллахи ва баракятух",
  _normalizeTransliterationKey("Assalaamu 'alaykum wa rahmatullah"):
      "Ас-саляму 'аляйкум ва рахматуллах",
  _normalizeTransliterationKey(
        "Assalaamu'alaynaa wa'alaa'ibaadillaahissaliheen",
      ):
      "Ас-саляму 'аляйна ва 'аля 'ибадилляхис-салихин",
  _normalizeTransliterationKey(
        'Attahiyyaatu lilaahi wassalawaatu wattayyibaatu',
      ):
      'Ат-тахийяту лилляхи вас-салявату ват-таййибату',
  _normalizeTransliterationKey('Bismillah'): 'Бисмиллях',
  _normalizeTransliterationKey('Bismillahir rahmanir rahim'):
      'Бисмилляхир-рахманир-рахим',
  _normalizeTransliterationKey('Ihdinas siratal mustaqim'):
      'Ихдинас-сыраталь-мустакым',
  _normalizeTransliterationKey('Ilaahinnas'): 'Иляхин-нас',
  _normalizeTransliterationKey('Innaka hameedun Majeed'):
      'Иннака хамидун маджид',
  _normalizeTransliterationKey("Iyyaka na'budu wa iyyaka nasta'in"):
      "Ийяка на'буду ва ийяка наста'ин",
  _normalizeTransliterationKey(
        "Kamaa baarakta 'alaa Ibraheem wa 'alaa aali Ibraheem",
      ):
      "Кама баракта 'аля Ибрахима ва 'аля али Ибрахим",
  _normalizeTransliterationKey(
        "Kamaa salyta 'ala Ibraheem wa 'ala aali Ibraheem",
      ):
      "Кама салляйта 'аля Ибрахима ва 'аля али Ибрахим",
  _normalizeTransliterationKey('Lam Yalid Wa Lam Yūlad'):
      'Лям ялид ва лям юляд',
  _normalizeTransliterationKey('Maliki yawmiddin'): 'Малики йаумид-дин',
  _normalizeTransliterationKey('Malikinnas'): 'Маликин-нас',
  _normalizeTransliterationKey('Min sharri maa khalaq'):
      'Мин шарри ма халяк',
  _normalizeTransliterationKey('Min sharril waswaasil khannaas'):
      'Мин шарриль-васвасиль-ханнас',
  _normalizeTransliterationKey('Minal jinnati wannas'):
      'Миналь-джиннати ван-нас',
  _normalizeTransliterationKey("QuI a'oothu birabbil falaq"):
      "Куль а'узу бираббиль-фаляк",
  _normalizeTransliterationKey("QuI a'oothu birabbinnas"):
      "Куль а'узу бираббин-нас",
  _normalizeTransliterationKey('Qul hu wal lahu ahad'):
      'Куль хуваллаху ахад',
  _normalizeTransliterationKey('Rabbanaa wa lakal hamd'):
      'Раббана ва лакаль-хамд',
  _normalizeTransliterationKey('Rabbighfirlee'): 'Раббигфирли',
  _normalizeTransliterationKey("Sami'-Allaahu liman hamidah"):
      "Сами'аллаху лиман хамидах",
  _normalizeTransliterationKey(
        "Siratal ladhina an'amta alaihim ghairil maghdubi alaihim wa lad dallin",
      ):
      "Сыраталлязина ан'амта 'аляйхим гайриль-магдуби 'аляйхим ва ляд-даллин",
  _normalizeTransliterationKey("Subhaana rabbiyal 'alaa"):
      "Субхана раббияль-'аля",
  _normalizeTransliterationKey("Subhaana rabbiyal 'atheem"):
      "Субхана раббияль-'азым",
  _normalizeTransliterationKey(
        "Wa baarik 'alaa Muhammad wa 'alaa aali Muhammad",
      ):
      "Ва барик 'аля Мухаммадин ва 'аля али Мухаммад",
  _normalizeTransliterationKey('Wa lam ya kul lahu kufuwan ahad'):
      'Ва лям якул-ляху куфуван ахад',
  _normalizeTransliterationKey('Wamin sharri ghasiqin ithaa waqab'):
      'Ва мин шарри гасикин иза вакаб',
  _normalizeTransliterationKey('Wamin sharri haasidin ithaa hasad'):
      'Ва мин шарри хасидин иза хасад',
  _normalizeTransliterationKey("Wamin sharrin-naffaathaati fil'uqad"):
      "Ва мин шаррин-наффасати филь-'укад",
  _normalizeTransliterationKey("А'узу билляхи минаш-шайтанир-раджим"):
      "А'узу билляхи минаш-шайтанир-раджим",
  _normalizeTransliterationKey('Аллаху акбар'): 'Аллаху акбар',
};
