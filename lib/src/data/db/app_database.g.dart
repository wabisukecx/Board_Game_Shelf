// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GamesTable extends Games with TableInfo<$GamesTable, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameKeyMeta = const VerificationMeta(
    'gameKey',
  );
  @override
  late final GeneratedColumn<String> gameKey = GeneratedColumn<String>(
    'game_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bggIdMeta = const VerificationMeta('bggId');
  @override
  late final GeneratedColumn<String> bggId = GeneratedColumn<String>(
    'bgg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gameKindMeta = const VerificationMeta(
    'gameKind',
  );
  @override
  late final GeneratedColumn<String> gameKind = GeneratedColumn<String>(
    'game_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(AppConstants.gameKindBase),
  );
  static const VerificationMeta _parentGameKeyMeta = const VerificationMeta(
    'parentGameKey',
  );
  @override
  late final GeneratedColumn<String> parentGameKey = GeneratedColumn<String>(
    'parent_game_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GameNames, String> names =
      GeneratedColumn<String>(
        'names',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GameNames>($GamesTable.$converternames);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _japaneseNameMeta = const VerificationMeta(
    'japaneseName',
  );
  @override
  late final GeneratedColumn<String> japaneseName = GeneratedColumn<String>(
    'japanese_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearPublishedMeta = const VerificationMeta(
    'yearPublished',
  );
  @override
  late final GeneratedColumn<String> yearPublished = GeneratedColumn<String>(
    'year_published',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMinPlayersMeta =
      const VerificationMeta('publisherMinPlayers');
  @override
  late final GeneratedColumn<int> publisherMinPlayers = GeneratedColumn<int>(
    'publisher_min_players',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMaxPlayersMeta =
      const VerificationMeta('publisherMaxPlayers');
  @override
  late final GeneratedColumn<int> publisherMaxPlayers = GeneratedColumn<int>(
    'publisher_max_players',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playingTimeMeta = const VerificationMeta(
    'playingTime',
  );
  @override
  late final GeneratedColumn<int> playingTime = GeneratedColumn<int>(
    'playing_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMinAgeMeta = const VerificationMeta(
    'publisherMinAge',
  );
  @override
  late final GeneratedColumn<int> publisherMinAge = GeneratedColumn<int>(
    'publisher_min_age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _communityBestPlayersMeta =
      const VerificationMeta('communityBestPlayers');
  @override
  late final GeneratedColumn<String> communityBestPlayers =
      GeneratedColumn<String>(
        'community_best_players',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _communityRecommendedPlayersMeta =
      const VerificationMeta('communityRecommendedPlayers');
  @override
  late final GeneratedColumn<String> communityRecommendedPlayers =
      GeneratedColumn<String>(
        'community_recommended_players',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _communityMinAgeMeta = const VerificationMeta(
    'communityMinAge',
  );
  @override
  late final GeneratedColumn<String> communityMinAge = GeneratedColumn<String>(
    'community_min_age',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SuggestedPlayerVotes, String>
  suggestedPlayerVotes =
      GeneratedColumn<String>(
        'suggested_player_votes',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<SuggestedPlayerVotes>(
        $GamesTable.$convertersuggestedPlayerVotes,
      );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionJaMeta = const VerificationMeta(
    'descriptionJa',
  );
  @override
  late final GeneratedColumn<String> descriptionJa = GeneratedColumn<String>(
    'description_ja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> mechanics =
      GeneratedColumn<String>(
        'mechanics',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($GamesTable.$convertermechanics);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> categories =
      GeneratedColumn<String>(
        'categories',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($GamesTable.$convertercategories);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> designers =
      GeneratedColumn<String>(
        'designers',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($GamesTable.$converterdesigners);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> publishers =
      GeneratedColumn<String>(
        'publishers',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($GamesTable.$converterpublishers);
  static const VerificationMeta _averageRatingMeta = const VerificationMeta(
    'averageRating',
  );
  @override
  late final GeneratedColumn<String> averageRating = GeneratedColumn<String>(
    'average_rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GameRanks, String> ranks =
      GeneratedColumn<String>(
        'ranks',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<GameRanks>($GamesTable.$converterranks);
  @override
  late final GeneratedColumnWithTypeConverter<UpdateHistory, String>
  updateHistory = GeneratedColumn<String>(
    'update_history',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<UpdateHistory>($GamesTable.$converterupdateHistory);
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawYamlMeta = const VerificationMeta(
    'rawYaml',
  );
  @override
  late final GeneratedColumn<String> rawYaml = GeneratedColumn<String>(
    'raw_yaml',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    gameKey,
    bggId,
    localId,
    gameKind,
    parentGameKey,
    names,
    name,
    japaneseName,
    yearPublished,
    publisherMinPlayers,
    publisherMaxPlayers,
    playingTime,
    publisherMinAge,
    communityBestPlayers,
    communityRecommendedPlayers,
    communityMinAge,
    suggestedPlayerVotes,
    description,
    descriptionJa,
    mechanics,
    categories,
    designers,
    publishers,
    averageRating,
    weight,
    ranks,
    updateHistory,
    thumbnailUrl,
    rawYaml,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<Game> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('game_key')) {
      context.handle(
        _gameKeyMeta,
        gameKey.isAcceptableOrUnknown(data['game_key']!, _gameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_gameKeyMeta);
    }
    if (data.containsKey('bgg_id')) {
      context.handle(
        _bggIdMeta,
        bggId.isAcceptableOrUnknown(data['bgg_id']!, _bggIdMeta),
      );
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('game_kind')) {
      context.handle(
        _gameKindMeta,
        gameKind.isAcceptableOrUnknown(data['game_kind']!, _gameKindMeta),
      );
    }
    if (data.containsKey('parent_game_key')) {
      context.handle(
        _parentGameKeyMeta,
        parentGameKey.isAcceptableOrUnknown(
          data['parent_game_key']!,
          _parentGameKeyMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('japanese_name')) {
      context.handle(
        _japaneseNameMeta,
        japaneseName.isAcceptableOrUnknown(
          data['japanese_name']!,
          _japaneseNameMeta,
        ),
      );
    }
    if (data.containsKey('year_published')) {
      context.handle(
        _yearPublishedMeta,
        yearPublished.isAcceptableOrUnknown(
          data['year_published']!,
          _yearPublishedMeta,
        ),
      );
    }
    if (data.containsKey('publisher_min_players')) {
      context.handle(
        _publisherMinPlayersMeta,
        publisherMinPlayers.isAcceptableOrUnknown(
          data['publisher_min_players']!,
          _publisherMinPlayersMeta,
        ),
      );
    }
    if (data.containsKey('publisher_max_players')) {
      context.handle(
        _publisherMaxPlayersMeta,
        publisherMaxPlayers.isAcceptableOrUnknown(
          data['publisher_max_players']!,
          _publisherMaxPlayersMeta,
        ),
      );
    }
    if (data.containsKey('playing_time')) {
      context.handle(
        _playingTimeMeta,
        playingTime.isAcceptableOrUnknown(
          data['playing_time']!,
          _playingTimeMeta,
        ),
      );
    }
    if (data.containsKey('publisher_min_age')) {
      context.handle(
        _publisherMinAgeMeta,
        publisherMinAge.isAcceptableOrUnknown(
          data['publisher_min_age']!,
          _publisherMinAgeMeta,
        ),
      );
    }
    if (data.containsKey('community_best_players')) {
      context.handle(
        _communityBestPlayersMeta,
        communityBestPlayers.isAcceptableOrUnknown(
          data['community_best_players']!,
          _communityBestPlayersMeta,
        ),
      );
    }
    if (data.containsKey('community_recommended_players')) {
      context.handle(
        _communityRecommendedPlayersMeta,
        communityRecommendedPlayers.isAcceptableOrUnknown(
          data['community_recommended_players']!,
          _communityRecommendedPlayersMeta,
        ),
      );
    }
    if (data.containsKey('community_min_age')) {
      context.handle(
        _communityMinAgeMeta,
        communityMinAge.isAcceptableOrUnknown(
          data['community_min_age']!,
          _communityMinAgeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('description_ja')) {
      context.handle(
        _descriptionJaMeta,
        descriptionJa.isAcceptableOrUnknown(
          data['description_ja']!,
          _descriptionJaMeta,
        ),
      );
    }
    if (data.containsKey('average_rating')) {
      context.handle(
        _averageRatingMeta,
        averageRating.isAcceptableOrUnknown(
          data['average_rating']!,
          _averageRatingMeta,
        ),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('raw_yaml')) {
      context.handle(
        _rawYamlMeta,
        rawYaml.isAcceptableOrUnknown(data['raw_yaml']!, _rawYamlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameKey};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      gameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_key'],
      )!,
      bggId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bgg_id'],
      ),
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      ),
      gameKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_kind'],
      )!,
      parentGameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_game_key'],
      ),
      names: $GamesTable.$converternames.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}names'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      japaneseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}japanese_name'],
      ),
      yearPublished: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_published'],
      ),
      publisherMinPlayers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}publisher_min_players'],
      ),
      publisherMaxPlayers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}publisher_max_players'],
      ),
      playingTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playing_time'],
      ),
      publisherMinAge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}publisher_min_age'],
      ),
      communityBestPlayers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}community_best_players'],
      ),
      communityRecommendedPlayers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}community_recommended_players'],
      ),
      communityMinAge: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}community_min_age'],
      ),
      suggestedPlayerVotes: $GamesTable.$convertersuggestedPlayerVotes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}suggested_player_votes'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      descriptionJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_ja'],
      ),
      mechanics: $GamesTable.$convertermechanics.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mechanics'],
        )!,
      ),
      categories: $GamesTable.$convertercategories.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}categories'],
        )!,
      ),
      designers: $GamesTable.$converterdesigners.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}designers'],
        )!,
      ),
      publishers: $GamesTable.$converterpublishers.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}publishers'],
        )!,
      ),
      averageRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}average_rating'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      ranks: $GamesTable.$converterranks.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ranks'],
        )!,
      ),
      updateHistory: $GamesTable.$converterupdateHistory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}update_history'],
        )!,
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      rawYaml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_yaml'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }

  static TypeConverter<GameNames, String> $converternames =
      const GameNamesConverter();
  static TypeConverter<SuggestedPlayerVotes, String>
  $convertersuggestedPlayerVotes = const SuggestedPlayerVotesConverter();
  static TypeConverter<List<String>, String> $convertermechanics =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertercategories =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterdesigners =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterpublishers =
      const StringListConverter();
  static TypeConverter<GameRanks, String> $converterranks =
      const GameRanksConverter();
  static TypeConverter<UpdateHistory, String> $converterupdateHistory =
      const UpdateHistoryConverter();
}

class Game extends DataClass implements Insertable<Game> {
  final String gameKey;
  final String? bggId;
  final String? localId;
  final String gameKind;
  final String? parentGameKey;
  final GameNames names;
  final String name;
  final String? japaneseName;
  final String? yearPublished;
  final int? publisherMinPlayers;
  final int? publisherMaxPlayers;
  final int? playingTime;
  final int? publisherMinAge;
  final String? communityBestPlayers;
  final String? communityRecommendedPlayers;
  final String? communityMinAge;
  final SuggestedPlayerVotes suggestedPlayerVotes;
  final String? description;
  final String? descriptionJa;
  final List<String> mechanics;
  final List<String> categories;
  final List<String> designers;
  final List<String> publishers;
  final String? averageRating;
  final double? weight;
  final GameRanks ranks;
  final UpdateHistory updateHistory;
  final String? thumbnailUrl;
  final String? rawYaml;
  final DateTime updatedAt;
  const Game({
    required this.gameKey,
    this.bggId,
    this.localId,
    required this.gameKind,
    this.parentGameKey,
    required this.names,
    required this.name,
    this.japaneseName,
    this.yearPublished,
    this.publisherMinPlayers,
    this.publisherMaxPlayers,
    this.playingTime,
    this.publisherMinAge,
    this.communityBestPlayers,
    this.communityRecommendedPlayers,
    this.communityMinAge,
    required this.suggestedPlayerVotes,
    this.description,
    this.descriptionJa,
    required this.mechanics,
    required this.categories,
    required this.designers,
    required this.publishers,
    this.averageRating,
    this.weight,
    required this.ranks,
    required this.updateHistory,
    this.thumbnailUrl,
    this.rawYaml,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['game_key'] = Variable<String>(gameKey);
    if (!nullToAbsent || bggId != null) {
      map['bgg_id'] = Variable<String>(bggId);
    }
    if (!nullToAbsent || localId != null) {
      map['local_id'] = Variable<String>(localId);
    }
    map['game_kind'] = Variable<String>(gameKind);
    if (!nullToAbsent || parentGameKey != null) {
      map['parent_game_key'] = Variable<String>(parentGameKey);
    }
    {
      map['names'] = Variable<String>($GamesTable.$converternames.toSql(names));
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || japaneseName != null) {
      map['japanese_name'] = Variable<String>(japaneseName);
    }
    if (!nullToAbsent || yearPublished != null) {
      map['year_published'] = Variable<String>(yearPublished);
    }
    if (!nullToAbsent || publisherMinPlayers != null) {
      map['publisher_min_players'] = Variable<int>(publisherMinPlayers);
    }
    if (!nullToAbsent || publisherMaxPlayers != null) {
      map['publisher_max_players'] = Variable<int>(publisherMaxPlayers);
    }
    if (!nullToAbsent || playingTime != null) {
      map['playing_time'] = Variable<int>(playingTime);
    }
    if (!nullToAbsent || publisherMinAge != null) {
      map['publisher_min_age'] = Variable<int>(publisherMinAge);
    }
    if (!nullToAbsent || communityBestPlayers != null) {
      map['community_best_players'] = Variable<String>(communityBestPlayers);
    }
    if (!nullToAbsent || communityRecommendedPlayers != null) {
      map['community_recommended_players'] = Variable<String>(
        communityRecommendedPlayers,
      );
    }
    if (!nullToAbsent || communityMinAge != null) {
      map['community_min_age'] = Variable<String>(communityMinAge);
    }
    {
      map['suggested_player_votes'] = Variable<String>(
        $GamesTable.$convertersuggestedPlayerVotes.toSql(suggestedPlayerVotes),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || descriptionJa != null) {
      map['description_ja'] = Variable<String>(descriptionJa);
    }
    {
      map['mechanics'] = Variable<String>(
        $GamesTable.$convertermechanics.toSql(mechanics),
      );
    }
    {
      map['categories'] = Variable<String>(
        $GamesTable.$convertercategories.toSql(categories),
      );
    }
    {
      map['designers'] = Variable<String>(
        $GamesTable.$converterdesigners.toSql(designers),
      );
    }
    {
      map['publishers'] = Variable<String>(
        $GamesTable.$converterpublishers.toSql(publishers),
      );
    }
    if (!nullToAbsent || averageRating != null) {
      map['average_rating'] = Variable<String>(averageRating);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    {
      map['ranks'] = Variable<String>($GamesTable.$converterranks.toSql(ranks));
    }
    {
      map['update_history'] = Variable<String>(
        $GamesTable.$converterupdateHistory.toSql(updateHistory),
      );
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || rawYaml != null) {
      map['raw_yaml'] = Variable<String>(rawYaml);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      gameKey: Value(gameKey),
      bggId: bggId == null && nullToAbsent
          ? const Value.absent()
          : Value(bggId),
      localId: localId == null && nullToAbsent
          ? const Value.absent()
          : Value(localId),
      gameKind: Value(gameKind),
      parentGameKey: parentGameKey == null && nullToAbsent
          ? const Value.absent()
          : Value(parentGameKey),
      names: Value(names),
      name: Value(name),
      japaneseName: japaneseName == null && nullToAbsent
          ? const Value.absent()
          : Value(japaneseName),
      yearPublished: yearPublished == null && nullToAbsent
          ? const Value.absent()
          : Value(yearPublished),
      publisherMinPlayers: publisherMinPlayers == null && nullToAbsent
          ? const Value.absent()
          : Value(publisherMinPlayers),
      publisherMaxPlayers: publisherMaxPlayers == null && nullToAbsent
          ? const Value.absent()
          : Value(publisherMaxPlayers),
      playingTime: playingTime == null && nullToAbsent
          ? const Value.absent()
          : Value(playingTime),
      publisherMinAge: publisherMinAge == null && nullToAbsent
          ? const Value.absent()
          : Value(publisherMinAge),
      communityBestPlayers: communityBestPlayers == null && nullToAbsent
          ? const Value.absent()
          : Value(communityBestPlayers),
      communityRecommendedPlayers:
          communityRecommendedPlayers == null && nullToAbsent
          ? const Value.absent()
          : Value(communityRecommendedPlayers),
      communityMinAge: communityMinAge == null && nullToAbsent
          ? const Value.absent()
          : Value(communityMinAge),
      suggestedPlayerVotes: Value(suggestedPlayerVotes),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      descriptionJa: descriptionJa == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionJa),
      mechanics: Value(mechanics),
      categories: Value(categories),
      designers: Value(designers),
      publishers: Value(publishers),
      averageRating: averageRating == null && nullToAbsent
          ? const Value.absent()
          : Value(averageRating),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      ranks: Value(ranks),
      updateHistory: Value(updateHistory),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      rawYaml: rawYaml == null && nullToAbsent
          ? const Value.absent()
          : Value(rawYaml),
      updatedAt: Value(updatedAt),
    );
  }

  factory Game.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      gameKey: serializer.fromJson<String>(json['gameKey']),
      bggId: serializer.fromJson<String?>(json['bggId']),
      localId: serializer.fromJson<String?>(json['localId']),
      gameKind: serializer.fromJson<String>(json['gameKind']),
      parentGameKey: serializer.fromJson<String?>(json['parentGameKey']),
      names: serializer.fromJson<GameNames>(json['names']),
      name: serializer.fromJson<String>(json['name']),
      japaneseName: serializer.fromJson<String?>(json['japaneseName']),
      yearPublished: serializer.fromJson<String?>(json['yearPublished']),
      publisherMinPlayers: serializer.fromJson<int?>(
        json['publisherMinPlayers'],
      ),
      publisherMaxPlayers: serializer.fromJson<int?>(
        json['publisherMaxPlayers'],
      ),
      playingTime: serializer.fromJson<int?>(json['playingTime']),
      publisherMinAge: serializer.fromJson<int?>(json['publisherMinAge']),
      communityBestPlayers: serializer.fromJson<String?>(
        json['communityBestPlayers'],
      ),
      communityRecommendedPlayers: serializer.fromJson<String?>(
        json['communityRecommendedPlayers'],
      ),
      communityMinAge: serializer.fromJson<String?>(json['communityMinAge']),
      suggestedPlayerVotes: serializer.fromJson<SuggestedPlayerVotes>(
        json['suggestedPlayerVotes'],
      ),
      description: serializer.fromJson<String?>(json['description']),
      descriptionJa: serializer.fromJson<String?>(json['descriptionJa']),
      mechanics: serializer.fromJson<List<String>>(json['mechanics']),
      categories: serializer.fromJson<List<String>>(json['categories']),
      designers: serializer.fromJson<List<String>>(json['designers']),
      publishers: serializer.fromJson<List<String>>(json['publishers']),
      averageRating: serializer.fromJson<String?>(json['averageRating']),
      weight: serializer.fromJson<double?>(json['weight']),
      ranks: serializer.fromJson<GameRanks>(json['ranks']),
      updateHistory: serializer.fromJson<UpdateHistory>(json['updateHistory']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      rawYaml: serializer.fromJson<String?>(json['rawYaml']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameKey': serializer.toJson<String>(gameKey),
      'bggId': serializer.toJson<String?>(bggId),
      'localId': serializer.toJson<String?>(localId),
      'gameKind': serializer.toJson<String>(gameKind),
      'parentGameKey': serializer.toJson<String?>(parentGameKey),
      'names': serializer.toJson<GameNames>(names),
      'name': serializer.toJson<String>(name),
      'japaneseName': serializer.toJson<String?>(japaneseName),
      'yearPublished': serializer.toJson<String?>(yearPublished),
      'publisherMinPlayers': serializer.toJson<int?>(publisherMinPlayers),
      'publisherMaxPlayers': serializer.toJson<int?>(publisherMaxPlayers),
      'playingTime': serializer.toJson<int?>(playingTime),
      'publisherMinAge': serializer.toJson<int?>(publisherMinAge),
      'communityBestPlayers': serializer.toJson<String?>(communityBestPlayers),
      'communityRecommendedPlayers': serializer.toJson<String?>(
        communityRecommendedPlayers,
      ),
      'communityMinAge': serializer.toJson<String?>(communityMinAge),
      'suggestedPlayerVotes': serializer.toJson<SuggestedPlayerVotes>(
        suggestedPlayerVotes,
      ),
      'description': serializer.toJson<String?>(description),
      'descriptionJa': serializer.toJson<String?>(descriptionJa),
      'mechanics': serializer.toJson<List<String>>(mechanics),
      'categories': serializer.toJson<List<String>>(categories),
      'designers': serializer.toJson<List<String>>(designers),
      'publishers': serializer.toJson<List<String>>(publishers),
      'averageRating': serializer.toJson<String?>(averageRating),
      'weight': serializer.toJson<double?>(weight),
      'ranks': serializer.toJson<GameRanks>(ranks),
      'updateHistory': serializer.toJson<UpdateHistory>(updateHistory),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'rawYaml': serializer.toJson<String?>(rawYaml),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Game copyWith({
    String? gameKey,
    Value<String?> bggId = const Value.absent(),
    Value<String?> localId = const Value.absent(),
    String? gameKind,
    Value<String?> parentGameKey = const Value.absent(),
    GameNames? names,
    String? name,
    Value<String?> japaneseName = const Value.absent(),
    Value<String?> yearPublished = const Value.absent(),
    Value<int?> publisherMinPlayers = const Value.absent(),
    Value<int?> publisherMaxPlayers = const Value.absent(),
    Value<int?> playingTime = const Value.absent(),
    Value<int?> publisherMinAge = const Value.absent(),
    Value<String?> communityBestPlayers = const Value.absent(),
    Value<String?> communityRecommendedPlayers = const Value.absent(),
    Value<String?> communityMinAge = const Value.absent(),
    SuggestedPlayerVotes? suggestedPlayerVotes,
    Value<String?> description = const Value.absent(),
    Value<String?> descriptionJa = const Value.absent(),
    List<String>? mechanics,
    List<String>? categories,
    List<String>? designers,
    List<String>? publishers,
    Value<String?> averageRating = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    GameRanks? ranks,
    UpdateHistory? updateHistory,
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<String?> rawYaml = const Value.absent(),
    DateTime? updatedAt,
  }) => Game(
    gameKey: gameKey ?? this.gameKey,
    bggId: bggId.present ? bggId.value : this.bggId,
    localId: localId.present ? localId.value : this.localId,
    gameKind: gameKind ?? this.gameKind,
    parentGameKey: parentGameKey.present
        ? parentGameKey.value
        : this.parentGameKey,
    names: names ?? this.names,
    name: name ?? this.name,
    japaneseName: japaneseName.present ? japaneseName.value : this.japaneseName,
    yearPublished: yearPublished.present
        ? yearPublished.value
        : this.yearPublished,
    publisherMinPlayers: publisherMinPlayers.present
        ? publisherMinPlayers.value
        : this.publisherMinPlayers,
    publisherMaxPlayers: publisherMaxPlayers.present
        ? publisherMaxPlayers.value
        : this.publisherMaxPlayers,
    playingTime: playingTime.present ? playingTime.value : this.playingTime,
    publisherMinAge: publisherMinAge.present
        ? publisherMinAge.value
        : this.publisherMinAge,
    communityBestPlayers: communityBestPlayers.present
        ? communityBestPlayers.value
        : this.communityBestPlayers,
    communityRecommendedPlayers: communityRecommendedPlayers.present
        ? communityRecommendedPlayers.value
        : this.communityRecommendedPlayers,
    communityMinAge: communityMinAge.present
        ? communityMinAge.value
        : this.communityMinAge,
    suggestedPlayerVotes: suggestedPlayerVotes ?? this.suggestedPlayerVotes,
    description: description.present ? description.value : this.description,
    descriptionJa: descriptionJa.present
        ? descriptionJa.value
        : this.descriptionJa,
    mechanics: mechanics ?? this.mechanics,
    categories: categories ?? this.categories,
    designers: designers ?? this.designers,
    publishers: publishers ?? this.publishers,
    averageRating: averageRating.present
        ? averageRating.value
        : this.averageRating,
    weight: weight.present ? weight.value : this.weight,
    ranks: ranks ?? this.ranks,
    updateHistory: updateHistory ?? this.updateHistory,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    rawYaml: rawYaml.present ? rawYaml.value : this.rawYaml,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      gameKey: data.gameKey.present ? data.gameKey.value : this.gameKey,
      bggId: data.bggId.present ? data.bggId.value : this.bggId,
      localId: data.localId.present ? data.localId.value : this.localId,
      gameKind: data.gameKind.present ? data.gameKind.value : this.gameKind,
      parentGameKey: data.parentGameKey.present
          ? data.parentGameKey.value
          : this.parentGameKey,
      names: data.names.present ? data.names.value : this.names,
      name: data.name.present ? data.name.value : this.name,
      japaneseName: data.japaneseName.present
          ? data.japaneseName.value
          : this.japaneseName,
      yearPublished: data.yearPublished.present
          ? data.yearPublished.value
          : this.yearPublished,
      publisherMinPlayers: data.publisherMinPlayers.present
          ? data.publisherMinPlayers.value
          : this.publisherMinPlayers,
      publisherMaxPlayers: data.publisherMaxPlayers.present
          ? data.publisherMaxPlayers.value
          : this.publisherMaxPlayers,
      playingTime: data.playingTime.present
          ? data.playingTime.value
          : this.playingTime,
      publisherMinAge: data.publisherMinAge.present
          ? data.publisherMinAge.value
          : this.publisherMinAge,
      communityBestPlayers: data.communityBestPlayers.present
          ? data.communityBestPlayers.value
          : this.communityBestPlayers,
      communityRecommendedPlayers: data.communityRecommendedPlayers.present
          ? data.communityRecommendedPlayers.value
          : this.communityRecommendedPlayers,
      communityMinAge: data.communityMinAge.present
          ? data.communityMinAge.value
          : this.communityMinAge,
      suggestedPlayerVotes: data.suggestedPlayerVotes.present
          ? data.suggestedPlayerVotes.value
          : this.suggestedPlayerVotes,
      description: data.description.present
          ? data.description.value
          : this.description,
      descriptionJa: data.descriptionJa.present
          ? data.descriptionJa.value
          : this.descriptionJa,
      mechanics: data.mechanics.present ? data.mechanics.value : this.mechanics,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      designers: data.designers.present ? data.designers.value : this.designers,
      publishers: data.publishers.present
          ? data.publishers.value
          : this.publishers,
      averageRating: data.averageRating.present
          ? data.averageRating.value
          : this.averageRating,
      weight: data.weight.present ? data.weight.value : this.weight,
      ranks: data.ranks.present ? data.ranks.value : this.ranks,
      updateHistory: data.updateHistory.present
          ? data.updateHistory.value
          : this.updateHistory,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      rawYaml: data.rawYaml.present ? data.rawYaml.value : this.rawYaml,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('gameKey: $gameKey, ')
          ..write('bggId: $bggId, ')
          ..write('localId: $localId, ')
          ..write('gameKind: $gameKind, ')
          ..write('parentGameKey: $parentGameKey, ')
          ..write('names: $names, ')
          ..write('name: $name, ')
          ..write('japaneseName: $japaneseName, ')
          ..write('yearPublished: $yearPublished, ')
          ..write('publisherMinPlayers: $publisherMinPlayers, ')
          ..write('publisherMaxPlayers: $publisherMaxPlayers, ')
          ..write('playingTime: $playingTime, ')
          ..write('publisherMinAge: $publisherMinAge, ')
          ..write('communityBestPlayers: $communityBestPlayers, ')
          ..write('communityRecommendedPlayers: $communityRecommendedPlayers, ')
          ..write('communityMinAge: $communityMinAge, ')
          ..write('suggestedPlayerVotes: $suggestedPlayerVotes, ')
          ..write('description: $description, ')
          ..write('descriptionJa: $descriptionJa, ')
          ..write('mechanics: $mechanics, ')
          ..write('categories: $categories, ')
          ..write('designers: $designers, ')
          ..write('publishers: $publishers, ')
          ..write('averageRating: $averageRating, ')
          ..write('weight: $weight, ')
          ..write('ranks: $ranks, ')
          ..write('updateHistory: $updateHistory, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('rawYaml: $rawYaml, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    gameKey,
    bggId,
    localId,
    gameKind,
    parentGameKey,
    names,
    name,
    japaneseName,
    yearPublished,
    publisherMinPlayers,
    publisherMaxPlayers,
    playingTime,
    publisherMinAge,
    communityBestPlayers,
    communityRecommendedPlayers,
    communityMinAge,
    suggestedPlayerVotes,
    description,
    descriptionJa,
    mechanics,
    categories,
    designers,
    publishers,
    averageRating,
    weight,
    ranks,
    updateHistory,
    thumbnailUrl,
    rawYaml,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.gameKey == this.gameKey &&
          other.bggId == this.bggId &&
          other.localId == this.localId &&
          other.gameKind == this.gameKind &&
          other.parentGameKey == this.parentGameKey &&
          other.names == this.names &&
          other.name == this.name &&
          other.japaneseName == this.japaneseName &&
          other.yearPublished == this.yearPublished &&
          other.publisherMinPlayers == this.publisherMinPlayers &&
          other.publisherMaxPlayers == this.publisherMaxPlayers &&
          other.playingTime == this.playingTime &&
          other.publisherMinAge == this.publisherMinAge &&
          other.communityBestPlayers == this.communityBestPlayers &&
          other.communityRecommendedPlayers ==
              this.communityRecommendedPlayers &&
          other.communityMinAge == this.communityMinAge &&
          other.suggestedPlayerVotes == this.suggestedPlayerVotes &&
          other.description == this.description &&
          other.descriptionJa == this.descriptionJa &&
          other.mechanics == this.mechanics &&
          other.categories == this.categories &&
          other.designers == this.designers &&
          other.publishers == this.publishers &&
          other.averageRating == this.averageRating &&
          other.weight == this.weight &&
          other.ranks == this.ranks &&
          other.updateHistory == this.updateHistory &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.rawYaml == this.rawYaml &&
          other.updatedAt == this.updatedAt);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<String> gameKey;
  final Value<String?> bggId;
  final Value<String?> localId;
  final Value<String> gameKind;
  final Value<String?> parentGameKey;
  final Value<GameNames> names;
  final Value<String> name;
  final Value<String?> japaneseName;
  final Value<String?> yearPublished;
  final Value<int?> publisherMinPlayers;
  final Value<int?> publisherMaxPlayers;
  final Value<int?> playingTime;
  final Value<int?> publisherMinAge;
  final Value<String?> communityBestPlayers;
  final Value<String?> communityRecommendedPlayers;
  final Value<String?> communityMinAge;
  final Value<SuggestedPlayerVotes> suggestedPlayerVotes;
  final Value<String?> description;
  final Value<String?> descriptionJa;
  final Value<List<String>> mechanics;
  final Value<List<String>> categories;
  final Value<List<String>> designers;
  final Value<List<String>> publishers;
  final Value<String?> averageRating;
  final Value<double?> weight;
  final Value<GameRanks> ranks;
  final Value<UpdateHistory> updateHistory;
  final Value<String?> thumbnailUrl;
  final Value<String?> rawYaml;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GamesCompanion({
    this.gameKey = const Value.absent(),
    this.bggId = const Value.absent(),
    this.localId = const Value.absent(),
    this.gameKind = const Value.absent(),
    this.parentGameKey = const Value.absent(),
    this.names = const Value.absent(),
    this.name = const Value.absent(),
    this.japaneseName = const Value.absent(),
    this.yearPublished = const Value.absent(),
    this.publisherMinPlayers = const Value.absent(),
    this.publisherMaxPlayers = const Value.absent(),
    this.playingTime = const Value.absent(),
    this.publisherMinAge = const Value.absent(),
    this.communityBestPlayers = const Value.absent(),
    this.communityRecommendedPlayers = const Value.absent(),
    this.communityMinAge = const Value.absent(),
    this.suggestedPlayerVotes = const Value.absent(),
    this.description = const Value.absent(),
    this.descriptionJa = const Value.absent(),
    this.mechanics = const Value.absent(),
    this.categories = const Value.absent(),
    this.designers = const Value.absent(),
    this.publishers = const Value.absent(),
    this.averageRating = const Value.absent(),
    this.weight = const Value.absent(),
    this.ranks = const Value.absent(),
    this.updateHistory = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rawYaml = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GamesCompanion.insert({
    required String gameKey,
    this.bggId = const Value.absent(),
    this.localId = const Value.absent(),
    this.gameKind = const Value.absent(),
    this.parentGameKey = const Value.absent(),
    required GameNames names,
    required String name,
    this.japaneseName = const Value.absent(),
    this.yearPublished = const Value.absent(),
    this.publisherMinPlayers = const Value.absent(),
    this.publisherMaxPlayers = const Value.absent(),
    this.playingTime = const Value.absent(),
    this.publisherMinAge = const Value.absent(),
    this.communityBestPlayers = const Value.absent(),
    this.communityRecommendedPlayers = const Value.absent(),
    this.communityMinAge = const Value.absent(),
    this.suggestedPlayerVotes = const Value.absent(),
    this.description = const Value.absent(),
    this.descriptionJa = const Value.absent(),
    this.mechanics = const Value.absent(),
    this.categories = const Value.absent(),
    this.designers = const Value.absent(),
    this.publishers = const Value.absent(),
    this.averageRating = const Value.absent(),
    this.weight = const Value.absent(),
    this.ranks = const Value.absent(),
    this.updateHistory = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rawYaml = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : gameKey = Value(gameKey),
       names = Value(names),
       name = Value(name);
  static Insertable<Game> custom({
    Expression<String>? gameKey,
    Expression<String>? bggId,
    Expression<String>? localId,
    Expression<String>? gameKind,
    Expression<String>? parentGameKey,
    Expression<String>? names,
    Expression<String>? name,
    Expression<String>? japaneseName,
    Expression<String>? yearPublished,
    Expression<int>? publisherMinPlayers,
    Expression<int>? publisherMaxPlayers,
    Expression<int>? playingTime,
    Expression<int>? publisherMinAge,
    Expression<String>? communityBestPlayers,
    Expression<String>? communityRecommendedPlayers,
    Expression<String>? communityMinAge,
    Expression<String>? suggestedPlayerVotes,
    Expression<String>? description,
    Expression<String>? descriptionJa,
    Expression<String>? mechanics,
    Expression<String>? categories,
    Expression<String>? designers,
    Expression<String>? publishers,
    Expression<String>? averageRating,
    Expression<double>? weight,
    Expression<String>? ranks,
    Expression<String>? updateHistory,
    Expression<String>? thumbnailUrl,
    Expression<String>? rawYaml,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gameKey != null) 'game_key': gameKey,
      if (bggId != null) 'bgg_id': bggId,
      if (localId != null) 'local_id': localId,
      if (gameKind != null) 'game_kind': gameKind,
      if (parentGameKey != null) 'parent_game_key': parentGameKey,
      if (names != null) 'names': names,
      if (name != null) 'name': name,
      if (japaneseName != null) 'japanese_name': japaneseName,
      if (yearPublished != null) 'year_published': yearPublished,
      if (publisherMinPlayers != null)
        'publisher_min_players': publisherMinPlayers,
      if (publisherMaxPlayers != null)
        'publisher_max_players': publisherMaxPlayers,
      if (playingTime != null) 'playing_time': playingTime,
      if (publisherMinAge != null) 'publisher_min_age': publisherMinAge,
      if (communityBestPlayers != null)
        'community_best_players': communityBestPlayers,
      if (communityRecommendedPlayers != null)
        'community_recommended_players': communityRecommendedPlayers,
      if (communityMinAge != null) 'community_min_age': communityMinAge,
      if (suggestedPlayerVotes != null)
        'suggested_player_votes': suggestedPlayerVotes,
      if (description != null) 'description': description,
      if (descriptionJa != null) 'description_ja': descriptionJa,
      if (mechanics != null) 'mechanics': mechanics,
      if (categories != null) 'categories': categories,
      if (designers != null) 'designers': designers,
      if (publishers != null) 'publishers': publishers,
      if (averageRating != null) 'average_rating': averageRating,
      if (weight != null) 'weight': weight,
      if (ranks != null) 'ranks': ranks,
      if (updateHistory != null) 'update_history': updateHistory,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (rawYaml != null) 'raw_yaml': rawYaml,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GamesCompanion copyWith({
    Value<String>? gameKey,
    Value<String?>? bggId,
    Value<String?>? localId,
    Value<String>? gameKind,
    Value<String?>? parentGameKey,
    Value<GameNames>? names,
    Value<String>? name,
    Value<String?>? japaneseName,
    Value<String?>? yearPublished,
    Value<int?>? publisherMinPlayers,
    Value<int?>? publisherMaxPlayers,
    Value<int?>? playingTime,
    Value<int?>? publisherMinAge,
    Value<String?>? communityBestPlayers,
    Value<String?>? communityRecommendedPlayers,
    Value<String?>? communityMinAge,
    Value<SuggestedPlayerVotes>? suggestedPlayerVotes,
    Value<String?>? description,
    Value<String?>? descriptionJa,
    Value<List<String>>? mechanics,
    Value<List<String>>? categories,
    Value<List<String>>? designers,
    Value<List<String>>? publishers,
    Value<String?>? averageRating,
    Value<double?>? weight,
    Value<GameRanks>? ranks,
    Value<UpdateHistory>? updateHistory,
    Value<String?>? thumbnailUrl,
    Value<String?>? rawYaml,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GamesCompanion(
      gameKey: gameKey ?? this.gameKey,
      bggId: bggId ?? this.bggId,
      localId: localId ?? this.localId,
      gameKind: gameKind ?? this.gameKind,
      parentGameKey: parentGameKey ?? this.parentGameKey,
      names: names ?? this.names,
      name: name ?? this.name,
      japaneseName: japaneseName ?? this.japaneseName,
      yearPublished: yearPublished ?? this.yearPublished,
      publisherMinPlayers: publisherMinPlayers ?? this.publisherMinPlayers,
      publisherMaxPlayers: publisherMaxPlayers ?? this.publisherMaxPlayers,
      playingTime: playingTime ?? this.playingTime,
      publisherMinAge: publisherMinAge ?? this.publisherMinAge,
      communityBestPlayers: communityBestPlayers ?? this.communityBestPlayers,
      communityRecommendedPlayers:
          communityRecommendedPlayers ?? this.communityRecommendedPlayers,
      communityMinAge: communityMinAge ?? this.communityMinAge,
      suggestedPlayerVotes: suggestedPlayerVotes ?? this.suggestedPlayerVotes,
      description: description ?? this.description,
      descriptionJa: descriptionJa ?? this.descriptionJa,
      mechanics: mechanics ?? this.mechanics,
      categories: categories ?? this.categories,
      designers: designers ?? this.designers,
      publishers: publishers ?? this.publishers,
      averageRating: averageRating ?? this.averageRating,
      weight: weight ?? this.weight,
      ranks: ranks ?? this.ranks,
      updateHistory: updateHistory ?? this.updateHistory,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rawYaml: rawYaml ?? this.rawYaml,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameKey.present) {
      map['game_key'] = Variable<String>(gameKey.value);
    }
    if (bggId.present) {
      map['bgg_id'] = Variable<String>(bggId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (gameKind.present) {
      map['game_kind'] = Variable<String>(gameKind.value);
    }
    if (parentGameKey.present) {
      map['parent_game_key'] = Variable<String>(parentGameKey.value);
    }
    if (names.present) {
      map['names'] = Variable<String>(
        $GamesTable.$converternames.toSql(names.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (japaneseName.present) {
      map['japanese_name'] = Variable<String>(japaneseName.value);
    }
    if (yearPublished.present) {
      map['year_published'] = Variable<String>(yearPublished.value);
    }
    if (publisherMinPlayers.present) {
      map['publisher_min_players'] = Variable<int>(publisherMinPlayers.value);
    }
    if (publisherMaxPlayers.present) {
      map['publisher_max_players'] = Variable<int>(publisherMaxPlayers.value);
    }
    if (playingTime.present) {
      map['playing_time'] = Variable<int>(playingTime.value);
    }
    if (publisherMinAge.present) {
      map['publisher_min_age'] = Variable<int>(publisherMinAge.value);
    }
    if (communityBestPlayers.present) {
      map['community_best_players'] = Variable<String>(
        communityBestPlayers.value,
      );
    }
    if (communityRecommendedPlayers.present) {
      map['community_recommended_players'] = Variable<String>(
        communityRecommendedPlayers.value,
      );
    }
    if (communityMinAge.present) {
      map['community_min_age'] = Variable<String>(communityMinAge.value);
    }
    if (suggestedPlayerVotes.present) {
      map['suggested_player_votes'] = Variable<String>(
        $GamesTable.$convertersuggestedPlayerVotes.toSql(
          suggestedPlayerVotes.value,
        ),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (descriptionJa.present) {
      map['description_ja'] = Variable<String>(descriptionJa.value);
    }
    if (mechanics.present) {
      map['mechanics'] = Variable<String>(
        $GamesTable.$convertermechanics.toSql(mechanics.value),
      );
    }
    if (categories.present) {
      map['categories'] = Variable<String>(
        $GamesTable.$convertercategories.toSql(categories.value),
      );
    }
    if (designers.present) {
      map['designers'] = Variable<String>(
        $GamesTable.$converterdesigners.toSql(designers.value),
      );
    }
    if (publishers.present) {
      map['publishers'] = Variable<String>(
        $GamesTable.$converterpublishers.toSql(publishers.value),
      );
    }
    if (averageRating.present) {
      map['average_rating'] = Variable<String>(averageRating.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (ranks.present) {
      map['ranks'] = Variable<String>(
        $GamesTable.$converterranks.toSql(ranks.value),
      );
    }
    if (updateHistory.present) {
      map['update_history'] = Variable<String>(
        $GamesTable.$converterupdateHistory.toSql(updateHistory.value),
      );
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (rawYaml.present) {
      map['raw_yaml'] = Variable<String>(rawYaml.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('gameKey: $gameKey, ')
          ..write('bggId: $bggId, ')
          ..write('localId: $localId, ')
          ..write('gameKind: $gameKind, ')
          ..write('parentGameKey: $parentGameKey, ')
          ..write('names: $names, ')
          ..write('name: $name, ')
          ..write('japaneseName: $japaneseName, ')
          ..write('yearPublished: $yearPublished, ')
          ..write('publisherMinPlayers: $publisherMinPlayers, ')
          ..write('publisherMaxPlayers: $publisherMaxPlayers, ')
          ..write('playingTime: $playingTime, ')
          ..write('publisherMinAge: $publisherMinAge, ')
          ..write('communityBestPlayers: $communityBestPlayers, ')
          ..write('communityRecommendedPlayers: $communityRecommendedPlayers, ')
          ..write('communityMinAge: $communityMinAge, ')
          ..write('suggestedPlayerVotes: $suggestedPlayerVotes, ')
          ..write('description: $description, ')
          ..write('descriptionJa: $descriptionJa, ')
          ..write('mechanics: $mechanics, ')
          ..write('categories: $categories, ')
          ..write('designers: $designers, ')
          ..write('publishers: $publishers, ')
          ..write('averageRating: $averageRating, ')
          ..write('weight: $weight, ')
          ..write('ranks: $ranks, ')
          ..write('updateHistory: $updateHistory, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('rawYaml: $rawYaml, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionEntriesTable extends CollectionEntries
    with TableInfo<$CollectionEntriesTable, CollectionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameKeyMeta = const VerificationMeta(
    'gameKey',
  );
  @override
  late final GeneratedColumn<String> gameKey = GeneratedColumn<String>(
    'game_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (game_key)',
    ),
  );
  static const VerificationMeta _ownedMeta = const VerificationMeta('owned');
  @override
  late final GeneratedColumn<bool> owned = GeneratedColumn<bool>(
    'owned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("owned" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _acquiredDateMeta = const VerificationMeta(
    'acquiredDate',
  );
  @override
  late final GeneratedColumn<String> acquiredDate = GeneratedColumn<String>(
    'acquired_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storageLocationMeta = const VerificationMeta(
    'storageLocation',
  );
  @override
  late final GeneratedColumn<String> storageLocation = GeneratedColumn<String>(
    'storage_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    gameKey,
    owned,
    acquiredDate,
    condition,
    storageLocation,
    memo,
    purchasePrice,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('game_key')) {
      context.handle(
        _gameKeyMeta,
        gameKey.isAcceptableOrUnknown(data['game_key']!, _gameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_gameKeyMeta);
    }
    if (data.containsKey('owned')) {
      context.handle(
        _ownedMeta,
        owned.isAcceptableOrUnknown(data['owned']!, _ownedMeta),
      );
    }
    if (data.containsKey('acquired_date')) {
      context.handle(
        _acquiredDateMeta,
        acquiredDate.isAcceptableOrUnknown(
          data['acquired_date']!,
          _acquiredDateMeta,
        ),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('storage_location')) {
      context.handle(
        _storageLocationMeta,
        storageLocation.isAcceptableOrUnknown(
          data['storage_location']!,
          _storageLocationMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameKey};
  @override
  CollectionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionEntry(
      gameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_key'],
      )!,
      owned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}owned'],
      )!,
      acquiredDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acquired_date'],
      ),
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      storageLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_location'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CollectionEntriesTable createAlias(String alias) {
    return $CollectionEntriesTable(attachedDatabase, alias);
  }
}

class CollectionEntry extends DataClass implements Insertable<CollectionEntry> {
  final String gameKey;
  final bool owned;
  final String? acquiredDate;
  final String? condition;
  final String? storageLocation;
  final String? memo;
  final double? purchasePrice;
  final DateTime updatedAt;
  const CollectionEntry({
    required this.gameKey,
    required this.owned,
    this.acquiredDate,
    this.condition,
    this.storageLocation,
    this.memo,
    this.purchasePrice,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['game_key'] = Variable<String>(gameKey);
    map['owned'] = Variable<bool>(owned);
    if (!nullToAbsent || acquiredDate != null) {
      map['acquired_date'] = Variable<String>(acquiredDate);
    }
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || storageLocation != null) {
      map['storage_location'] = Variable<String>(storageLocation);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || purchasePrice != null) {
      map['purchase_price'] = Variable<double>(purchasePrice);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CollectionEntriesCompanion toCompanion(bool nullToAbsent) {
    return CollectionEntriesCompanion(
      gameKey: Value(gameKey),
      owned: Value(owned),
      acquiredDate: acquiredDate == null && nullToAbsent
          ? const Value.absent()
          : Value(acquiredDate),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      storageLocation: storageLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(storageLocation),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      purchasePrice: purchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePrice),
      updatedAt: Value(updatedAt),
    );
  }

  factory CollectionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionEntry(
      gameKey: serializer.fromJson<String>(json['gameKey']),
      owned: serializer.fromJson<bool>(json['owned']),
      acquiredDate: serializer.fromJson<String?>(json['acquiredDate']),
      condition: serializer.fromJson<String?>(json['condition']),
      storageLocation: serializer.fromJson<String?>(json['storageLocation']),
      memo: serializer.fromJson<String?>(json['memo']),
      purchasePrice: serializer.fromJson<double?>(json['purchasePrice']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameKey': serializer.toJson<String>(gameKey),
      'owned': serializer.toJson<bool>(owned),
      'acquiredDate': serializer.toJson<String?>(acquiredDate),
      'condition': serializer.toJson<String?>(condition),
      'storageLocation': serializer.toJson<String?>(storageLocation),
      'memo': serializer.toJson<String?>(memo),
      'purchasePrice': serializer.toJson<double?>(purchasePrice),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CollectionEntry copyWith({
    String? gameKey,
    bool? owned,
    Value<String?> acquiredDate = const Value.absent(),
    Value<String?> condition = const Value.absent(),
    Value<String?> storageLocation = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<double?> purchasePrice = const Value.absent(),
    DateTime? updatedAt,
  }) => CollectionEntry(
    gameKey: gameKey ?? this.gameKey,
    owned: owned ?? this.owned,
    acquiredDate: acquiredDate.present ? acquiredDate.value : this.acquiredDate,
    condition: condition.present ? condition.value : this.condition,
    storageLocation: storageLocation.present
        ? storageLocation.value
        : this.storageLocation,
    memo: memo.present ? memo.value : this.memo,
    purchasePrice: purchasePrice.present
        ? purchasePrice.value
        : this.purchasePrice,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CollectionEntry copyWithCompanion(CollectionEntriesCompanion data) {
    return CollectionEntry(
      gameKey: data.gameKey.present ? data.gameKey.value : this.gameKey,
      owned: data.owned.present ? data.owned.value : this.owned,
      acquiredDate: data.acquiredDate.present
          ? data.acquiredDate.value
          : this.acquiredDate,
      condition: data.condition.present ? data.condition.value : this.condition,
      storageLocation: data.storageLocation.present
          ? data.storageLocation.value
          : this.storageLocation,
      memo: data.memo.present ? data.memo.value : this.memo,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionEntry(')
          ..write('gameKey: $gameKey, ')
          ..write('owned: $owned, ')
          ..write('acquiredDate: $acquiredDate, ')
          ..write('condition: $condition, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('memo: $memo, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    gameKey,
    owned,
    acquiredDate,
    condition,
    storageLocation,
    memo,
    purchasePrice,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionEntry &&
          other.gameKey == this.gameKey &&
          other.owned == this.owned &&
          other.acquiredDate == this.acquiredDate &&
          other.condition == this.condition &&
          other.storageLocation == this.storageLocation &&
          other.memo == this.memo &&
          other.purchasePrice == this.purchasePrice &&
          other.updatedAt == this.updatedAt);
}

class CollectionEntriesCompanion extends UpdateCompanion<CollectionEntry> {
  final Value<String> gameKey;
  final Value<bool> owned;
  final Value<String?> acquiredDate;
  final Value<String?> condition;
  final Value<String?> storageLocation;
  final Value<String?> memo;
  final Value<double?> purchasePrice;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CollectionEntriesCompanion({
    this.gameKey = const Value.absent(),
    this.owned = const Value.absent(),
    this.acquiredDate = const Value.absent(),
    this.condition = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.memo = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionEntriesCompanion.insert({
    required String gameKey,
    this.owned = const Value.absent(),
    this.acquiredDate = const Value.absent(),
    this.condition = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.memo = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : gameKey = Value(gameKey);
  static Insertable<CollectionEntry> custom({
    Expression<String>? gameKey,
    Expression<bool>? owned,
    Expression<String>? acquiredDate,
    Expression<String>? condition,
    Expression<String>? storageLocation,
    Expression<String>? memo,
    Expression<double>? purchasePrice,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gameKey != null) 'game_key': gameKey,
      if (owned != null) 'owned': owned,
      if (acquiredDate != null) 'acquired_date': acquiredDate,
      if (condition != null) 'condition': condition,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (memo != null) 'memo': memo,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionEntriesCompanion copyWith({
    Value<String>? gameKey,
    Value<bool>? owned,
    Value<String?>? acquiredDate,
    Value<String?>? condition,
    Value<String?>? storageLocation,
    Value<String?>? memo,
    Value<double?>? purchasePrice,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CollectionEntriesCompanion(
      gameKey: gameKey ?? this.gameKey,
      owned: owned ?? this.owned,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      condition: condition ?? this.condition,
      storageLocation: storageLocation ?? this.storageLocation,
      memo: memo ?? this.memo,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameKey.present) {
      map['game_key'] = Variable<String>(gameKey.value);
    }
    if (owned.present) {
      map['owned'] = Variable<bool>(owned.value);
    }
    if (acquiredDate.present) {
      map['acquired_date'] = Variable<String>(acquiredDate.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (storageLocation.present) {
      map['storage_location'] = Variable<String>(storageLocation.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionEntriesCompanion(')
          ..write('gameKey: $gameKey, ')
          ..write('owned: $owned, ')
          ..write('acquiredDate: $acquiredDate, ')
          ..write('condition: $condition, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('memo: $memo, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BarcodeMapEntriesTable extends BarcodeMapEntries
    with TableInfo<$BarcodeMapEntriesTable, BarcodeMapEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BarcodeMapEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _janCodeMeta = const VerificationMeta(
    'janCode',
  );
  @override
  late final GeneratedColumn<String> janCode = GeneratedColumn<String>(
    'jan_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameKeyMeta = const VerificationMeta(
    'gameKey',
  );
  @override
  late final GeneratedColumn<String> gameKey = GeneratedColumn<String>(
    'game_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (game_key)',
    ),
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [janCode, gameKey, resolvedAt, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'barcode_map';
  @override
  VerificationContext validateIntegrity(
    Insertable<BarcodeMapEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('jan_code')) {
      context.handle(
        _janCodeMeta,
        janCode.isAcceptableOrUnknown(data['jan_code']!, _janCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_janCodeMeta);
    }
    if (data.containsKey('game_key')) {
      context.handle(
        _gameKeyMeta,
        gameKey.isAcceptableOrUnknown(data['game_key']!, _gameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_gameKeyMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_resolvedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {janCode};
  @override
  BarcodeMapEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BarcodeMapEntry(
      janCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jan_code'],
      )!,
      gameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_key'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $BarcodeMapEntriesTable createAlias(String alias) {
    return $BarcodeMapEntriesTable(attachedDatabase, alias);
  }
}

class BarcodeMapEntry extends DataClass implements Insertable<BarcodeMapEntry> {
  final String janCode;
  final String gameKey;
  final DateTime resolvedAt;
  final String source;
  const BarcodeMapEntry({
    required this.janCode,
    required this.gameKey,
    required this.resolvedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['jan_code'] = Variable<String>(janCode);
    map['game_key'] = Variable<String>(gameKey);
    map['resolved_at'] = Variable<DateTime>(resolvedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  BarcodeMapEntriesCompanion toCompanion(bool nullToAbsent) {
    return BarcodeMapEntriesCompanion(
      janCode: Value(janCode),
      gameKey: Value(gameKey),
      resolvedAt: Value(resolvedAt),
      source: Value(source),
    );
  }

  factory BarcodeMapEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BarcodeMapEntry(
      janCode: serializer.fromJson<String>(json['janCode']),
      gameKey: serializer.fromJson<String>(json['gameKey']),
      resolvedAt: serializer.fromJson<DateTime>(json['resolvedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'janCode': serializer.toJson<String>(janCode),
      'gameKey': serializer.toJson<String>(gameKey),
      'resolvedAt': serializer.toJson<DateTime>(resolvedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  BarcodeMapEntry copyWith({
    String? janCode,
    String? gameKey,
    DateTime? resolvedAt,
    String? source,
  }) => BarcodeMapEntry(
    janCode: janCode ?? this.janCode,
    gameKey: gameKey ?? this.gameKey,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    source: source ?? this.source,
  );
  BarcodeMapEntry copyWithCompanion(BarcodeMapEntriesCompanion data) {
    return BarcodeMapEntry(
      janCode: data.janCode.present ? data.janCode.value : this.janCode,
      gameKey: data.gameKey.present ? data.gameKey.value : this.gameKey,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BarcodeMapEntry(')
          ..write('janCode: $janCode, ')
          ..write('gameKey: $gameKey, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(janCode, gameKey, resolvedAt, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BarcodeMapEntry &&
          other.janCode == this.janCode &&
          other.gameKey == this.gameKey &&
          other.resolvedAt == this.resolvedAt &&
          other.source == this.source);
}

class BarcodeMapEntriesCompanion extends UpdateCompanion<BarcodeMapEntry> {
  final Value<String> janCode;
  final Value<String> gameKey;
  final Value<DateTime> resolvedAt;
  final Value<String> source;
  final Value<int> rowid;
  const BarcodeMapEntriesCompanion({
    this.janCode = const Value.absent(),
    this.gameKey = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BarcodeMapEntriesCompanion.insert({
    required String janCode,
    required String gameKey,
    required DateTime resolvedAt,
    required String source,
    this.rowid = const Value.absent(),
  }) : janCode = Value(janCode),
       gameKey = Value(gameKey),
       resolvedAt = Value(resolvedAt),
       source = Value(source);
  static Insertable<BarcodeMapEntry> custom({
    Expression<String>? janCode,
    Expression<String>? gameKey,
    Expression<DateTime>? resolvedAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (janCode != null) 'jan_code': janCode,
      if (gameKey != null) 'game_key': gameKey,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BarcodeMapEntriesCompanion copyWith({
    Value<String>? janCode,
    Value<String>? gameKey,
    Value<DateTime>? resolvedAt,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return BarcodeMapEntriesCompanion(
      janCode: janCode ?? this.janCode,
      gameKey: gameKey ?? this.gameKey,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (janCode.present) {
      map['jan_code'] = Variable<String>(janCode.value);
    }
    if (gameKey.present) {
      map['game_key'] = Variable<String>(gameKey.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BarcodeMapEntriesCompanion(')
          ..write('janCode: $janCode, ')
          ..write('gameKey: $gameKey, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiCacheEntriesTable extends ApiCacheEntries
    with TableInfo<$ApiCacheEntriesTable, ApiCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, payload, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  ApiCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiCacheEntry(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $ApiCacheEntriesTable createAlias(String alias) {
    return $ApiCacheEntriesTable(attachedDatabase, alias);
  }
}

class ApiCacheEntry extends DataClass implements Insertable<ApiCacheEntry> {
  final String cacheKey;
  final String payload;
  final DateTime expiresAt;
  const ApiCacheEntry({
    required this.cacheKey,
    required this.payload,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload'] = Variable<String>(payload);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  ApiCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return ApiCacheEntriesCompanion(
      cacheKey: Value(cacheKey),
      payload: Value(payload),
      expiresAt: Value(expiresAt),
    );
  }

  factory ApiCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiCacheEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payload: serializer.fromJson<String>(json['payload']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payload': serializer.toJson<String>(payload),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  ApiCacheEntry copyWith({
    String? cacheKey,
    String? payload,
    DateTime? expiresAt,
  }) => ApiCacheEntry(
    cacheKey: cacheKey ?? this.cacheKey,
    payload: payload ?? this.payload,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  ApiCacheEntry copyWithCompanion(ApiCacheEntriesCompanion data) {
    return ApiCacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, payload, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiCacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.payload == this.payload &&
          other.expiresAt == this.expiresAt);
}

class ApiCacheEntriesCompanion extends UpdateCompanion<ApiCacheEntry> {
  final Value<String> cacheKey;
  final Value<String> payload;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const ApiCacheEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiCacheEntriesCompanion.insert({
    required String cacheKey,
    required String payload,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       payload = Value(payload),
       expiresAt = Value(expiresAt);
  static Insertable<ApiCacheEntry> custom({
    Expression<String>? cacheKey,
    Expression<String>? payload,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payload != null) 'payload': payload,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiCacheEntriesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? payload,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return ApiCacheEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      payload: payload ?? this.payload,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheEntriesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String? value;
  const SettingsEntry({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  SettingsEntry copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => SettingsEntry(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaySessionsTable extends PlaySessions
    with TableInfo<$PlaySessionsTable, PlaySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameKeyMeta = const VerificationMeta(
    'gameKey',
  );
  @override
  late final GeneratedColumn<String> gameKey = GeneratedColumn<String>(
    'game_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (game_key)',
    ),
  );
  static const VerificationMeta _playedDateMeta = const VerificationMeta(
    'playedDate',
  );
  @override
  late final GeneratedColumn<String> playedDate = GeneratedColumn<String>(
    'played_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerCountMeta = const VerificationMeta(
    'playerCount',
  );
  @override
  late final GeneratedColumn<int> playerCount = GeneratedColumn<int>(
    'player_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualPlayingTimeMeta = const VerificationMeta(
    'actualPlayingTime',
  );
  @override
  late final GeneratedColumn<int> actualPlayingTime = GeneratedColumn<int>(
    'actual_playing_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replayDesireMeta = const VerificationMeta(
    'replayDesire',
  );
  @override
  late final GeneratedColumn<int> replayDesire = GeneratedColumn<int>(
    'replay_desire',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _perceivedWeightMeta = const VerificationMeta(
    'perceivedWeight',
  );
  @override
  late final GeneratedColumn<double> perceivedWeight = GeneratedColumn<double>(
    'perceived_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _winnerMemoMeta = const VerificationMeta(
    'winnerMemo',
  );
  @override
  late final GeneratedColumn<String> winnerMemo = GeneratedColumn<String>(
    'winner_memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameKey,
    playedDate,
    playerCount,
    actualPlayingTime,
    notes,
    rating,
    replayDesire,
    perceivedWeight,
    winnerMemo,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_key')) {
      context.handle(
        _gameKeyMeta,
        gameKey.isAcceptableOrUnknown(data['game_key']!, _gameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_gameKeyMeta);
    }
    if (data.containsKey('played_date')) {
      context.handle(
        _playedDateMeta,
        playedDate.isAcceptableOrUnknown(data['played_date']!, _playedDateMeta),
      );
    } else if (isInserting) {
      context.missing(_playedDateMeta);
    }
    if (data.containsKey('player_count')) {
      context.handle(
        _playerCountMeta,
        playerCount.isAcceptableOrUnknown(
          data['player_count']!,
          _playerCountMeta,
        ),
      );
    }
    if (data.containsKey('actual_playing_time')) {
      context.handle(
        _actualPlayingTimeMeta,
        actualPlayingTime.isAcceptableOrUnknown(
          data['actual_playing_time']!,
          _actualPlayingTimeMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('replay_desire')) {
      context.handle(
        _replayDesireMeta,
        replayDesire.isAcceptableOrUnknown(
          data['replay_desire']!,
          _replayDesireMeta,
        ),
      );
    }
    if (data.containsKey('perceived_weight')) {
      context.handle(
        _perceivedWeightMeta,
        perceivedWeight.isAcceptableOrUnknown(
          data['perceived_weight']!,
          _perceivedWeightMeta,
        ),
      );
    }
    if (data.containsKey('winner_memo')) {
      context.handle(
        _winnerMemoMeta,
        winnerMemo.isAcceptableOrUnknown(data['winner_memo']!, _winnerMemoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaySession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_key'],
      )!,
      playedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}played_date'],
      )!,
      playerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_count'],
      ),
      actualPlayingTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_playing_time'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      replayDesire: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}replay_desire'],
      ),
      perceivedWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}perceived_weight'],
      ),
      winnerMemo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_memo'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlaySessionsTable createAlias(String alias) {
    return $PlaySessionsTable(attachedDatabase, alias);
  }
}

class PlaySession extends DataClass implements Insertable<PlaySession> {
  final int id;
  final String gameKey;
  final String playedDate;
  final int? playerCount;
  final int? actualPlayingTime;
  final String? notes;
  final int? rating;
  final int? replayDesire;
  final double? perceivedWeight;
  final String? winnerMemo;
  final DateTime createdAt;
  const PlaySession({
    required this.id,
    required this.gameKey,
    required this.playedDate,
    this.playerCount,
    this.actualPlayingTime,
    this.notes,
    this.rating,
    this.replayDesire,
    this.perceivedWeight,
    this.winnerMemo,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_key'] = Variable<String>(gameKey);
    map['played_date'] = Variable<String>(playedDate);
    if (!nullToAbsent || playerCount != null) {
      map['player_count'] = Variable<int>(playerCount);
    }
    if (!nullToAbsent || actualPlayingTime != null) {
      map['actual_playing_time'] = Variable<int>(actualPlayingTime);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || replayDesire != null) {
      map['replay_desire'] = Variable<int>(replayDesire);
    }
    if (!nullToAbsent || perceivedWeight != null) {
      map['perceived_weight'] = Variable<double>(perceivedWeight);
    }
    if (!nullToAbsent || winnerMemo != null) {
      map['winner_memo'] = Variable<String>(winnerMemo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlaySessionsCompanion toCompanion(bool nullToAbsent) {
    return PlaySessionsCompanion(
      id: Value(id),
      gameKey: Value(gameKey),
      playedDate: Value(playedDate),
      playerCount: playerCount == null && nullToAbsent
          ? const Value.absent()
          : Value(playerCount),
      actualPlayingTime: actualPlayingTime == null && nullToAbsent
          ? const Value.absent()
          : Value(actualPlayingTime),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      replayDesire: replayDesire == null && nullToAbsent
          ? const Value.absent()
          : Value(replayDesire),
      perceivedWeight: perceivedWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(perceivedWeight),
      winnerMemo: winnerMemo == null && nullToAbsent
          ? const Value.absent()
          : Value(winnerMemo),
      createdAt: Value(createdAt),
    );
  }

  factory PlaySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaySession(
      id: serializer.fromJson<int>(json['id']),
      gameKey: serializer.fromJson<String>(json['gameKey']),
      playedDate: serializer.fromJson<String>(json['playedDate']),
      playerCount: serializer.fromJson<int?>(json['playerCount']),
      actualPlayingTime: serializer.fromJson<int?>(json['actualPlayingTime']),
      notes: serializer.fromJson<String?>(json['notes']),
      rating: serializer.fromJson<int?>(json['rating']),
      replayDesire: serializer.fromJson<int?>(json['replayDesire']),
      perceivedWeight: serializer.fromJson<double?>(json['perceivedWeight']),
      winnerMemo: serializer.fromJson<String?>(json['winnerMemo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameKey': serializer.toJson<String>(gameKey),
      'playedDate': serializer.toJson<String>(playedDate),
      'playerCount': serializer.toJson<int?>(playerCount),
      'actualPlayingTime': serializer.toJson<int?>(actualPlayingTime),
      'notes': serializer.toJson<String?>(notes),
      'rating': serializer.toJson<int?>(rating),
      'replayDesire': serializer.toJson<int?>(replayDesire),
      'perceivedWeight': serializer.toJson<double?>(perceivedWeight),
      'winnerMemo': serializer.toJson<String?>(winnerMemo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlaySession copyWith({
    int? id,
    String? gameKey,
    String? playedDate,
    Value<int?> playerCount = const Value.absent(),
    Value<int?> actualPlayingTime = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> rating = const Value.absent(),
    Value<int?> replayDesire = const Value.absent(),
    Value<double?> perceivedWeight = const Value.absent(),
    Value<String?> winnerMemo = const Value.absent(),
    DateTime? createdAt,
  }) => PlaySession(
    id: id ?? this.id,
    gameKey: gameKey ?? this.gameKey,
    playedDate: playedDate ?? this.playedDate,
    playerCount: playerCount.present ? playerCount.value : this.playerCount,
    actualPlayingTime: actualPlayingTime.present
        ? actualPlayingTime.value
        : this.actualPlayingTime,
    notes: notes.present ? notes.value : this.notes,
    rating: rating.present ? rating.value : this.rating,
    replayDesire: replayDesire.present ? replayDesire.value : this.replayDesire,
    perceivedWeight: perceivedWeight.present
        ? perceivedWeight.value
        : this.perceivedWeight,
    winnerMemo: winnerMemo.present ? winnerMemo.value : this.winnerMemo,
    createdAt: createdAt ?? this.createdAt,
  );
  PlaySession copyWithCompanion(PlaySessionsCompanion data) {
    return PlaySession(
      id: data.id.present ? data.id.value : this.id,
      gameKey: data.gameKey.present ? data.gameKey.value : this.gameKey,
      playedDate: data.playedDate.present
          ? data.playedDate.value
          : this.playedDate,
      playerCount: data.playerCount.present
          ? data.playerCount.value
          : this.playerCount,
      actualPlayingTime: data.actualPlayingTime.present
          ? data.actualPlayingTime.value
          : this.actualPlayingTime,
      notes: data.notes.present ? data.notes.value : this.notes,
      rating: data.rating.present ? data.rating.value : this.rating,
      replayDesire: data.replayDesire.present
          ? data.replayDesire.value
          : this.replayDesire,
      perceivedWeight: data.perceivedWeight.present
          ? data.perceivedWeight.value
          : this.perceivedWeight,
      winnerMemo: data.winnerMemo.present
          ? data.winnerMemo.value
          : this.winnerMemo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaySession(')
          ..write('id: $id, ')
          ..write('gameKey: $gameKey, ')
          ..write('playedDate: $playedDate, ')
          ..write('playerCount: $playerCount, ')
          ..write('actualPlayingTime: $actualPlayingTime, ')
          ..write('notes: $notes, ')
          ..write('rating: $rating, ')
          ..write('replayDesire: $replayDesire, ')
          ..write('perceivedWeight: $perceivedWeight, ')
          ..write('winnerMemo: $winnerMemo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameKey,
    playedDate,
    playerCount,
    actualPlayingTime,
    notes,
    rating,
    replayDesire,
    perceivedWeight,
    winnerMemo,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySession &&
          other.id == this.id &&
          other.gameKey == this.gameKey &&
          other.playedDate == this.playedDate &&
          other.playerCount == this.playerCount &&
          other.actualPlayingTime == this.actualPlayingTime &&
          other.notes == this.notes &&
          other.rating == this.rating &&
          other.replayDesire == this.replayDesire &&
          other.perceivedWeight == this.perceivedWeight &&
          other.winnerMemo == this.winnerMemo &&
          other.createdAt == this.createdAt);
}

class PlaySessionsCompanion extends UpdateCompanion<PlaySession> {
  final Value<int> id;
  final Value<String> gameKey;
  final Value<String> playedDate;
  final Value<int?> playerCount;
  final Value<int?> actualPlayingTime;
  final Value<String?> notes;
  final Value<int?> rating;
  final Value<int?> replayDesire;
  final Value<double?> perceivedWeight;
  final Value<String?> winnerMemo;
  final Value<DateTime> createdAt;
  const PlaySessionsCompanion({
    this.id = const Value.absent(),
    this.gameKey = const Value.absent(),
    this.playedDate = const Value.absent(),
    this.playerCount = const Value.absent(),
    this.actualPlayingTime = const Value.absent(),
    this.notes = const Value.absent(),
    this.rating = const Value.absent(),
    this.replayDesire = const Value.absent(),
    this.perceivedWeight = const Value.absent(),
    this.winnerMemo = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlaySessionsCompanion.insert({
    this.id = const Value.absent(),
    required String gameKey,
    required String playedDate,
    this.playerCount = const Value.absent(),
    this.actualPlayingTime = const Value.absent(),
    this.notes = const Value.absent(),
    this.rating = const Value.absent(),
    this.replayDesire = const Value.absent(),
    this.perceivedWeight = const Value.absent(),
    this.winnerMemo = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : gameKey = Value(gameKey),
       playedDate = Value(playedDate);
  static Insertable<PlaySession> custom({
    Expression<int>? id,
    Expression<String>? gameKey,
    Expression<String>? playedDate,
    Expression<int>? playerCount,
    Expression<int>? actualPlayingTime,
    Expression<String>? notes,
    Expression<int>? rating,
    Expression<int>? replayDesire,
    Expression<double>? perceivedWeight,
    Expression<String>? winnerMemo,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameKey != null) 'game_key': gameKey,
      if (playedDate != null) 'played_date': playedDate,
      if (playerCount != null) 'player_count': playerCount,
      if (actualPlayingTime != null) 'actual_playing_time': actualPlayingTime,
      if (notes != null) 'notes': notes,
      if (rating != null) 'rating': rating,
      if (replayDesire != null) 'replay_desire': replayDesire,
      if (perceivedWeight != null) 'perceived_weight': perceivedWeight,
      if (winnerMemo != null) 'winner_memo': winnerMemo,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlaySessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? gameKey,
    Value<String>? playedDate,
    Value<int?>? playerCount,
    Value<int?>? actualPlayingTime,
    Value<String?>? notes,
    Value<int?>? rating,
    Value<int?>? replayDesire,
    Value<double?>? perceivedWeight,
    Value<String?>? winnerMemo,
    Value<DateTime>? createdAt,
  }) {
    return PlaySessionsCompanion(
      id: id ?? this.id,
      gameKey: gameKey ?? this.gameKey,
      playedDate: playedDate ?? this.playedDate,
      playerCount: playerCount ?? this.playerCount,
      actualPlayingTime: actualPlayingTime ?? this.actualPlayingTime,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      replayDesire: replayDesire ?? this.replayDesire,
      perceivedWeight: perceivedWeight ?? this.perceivedWeight,
      winnerMemo: winnerMemo ?? this.winnerMemo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameKey.present) {
      map['game_key'] = Variable<String>(gameKey.value);
    }
    if (playedDate.present) {
      map['played_date'] = Variable<String>(playedDate.value);
    }
    if (playerCount.present) {
      map['player_count'] = Variable<int>(playerCount.value);
    }
    if (actualPlayingTime.present) {
      map['actual_playing_time'] = Variable<int>(actualPlayingTime.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (replayDesire.present) {
      map['replay_desire'] = Variable<int>(replayDesire.value);
    }
    if (perceivedWeight.present) {
      map['perceived_weight'] = Variable<double>(perceivedWeight.value);
    }
    if (winnerMemo.present) {
      map['winner_memo'] = Variable<String>(winnerMemo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionsCompanion(')
          ..write('id: $id, ')
          ..write('gameKey: $gameKey, ')
          ..write('playedDate: $playedDate, ')
          ..write('playerCount: $playerCount, ')
          ..write('actualPlayingTime: $actualPlayingTime, ')
          ..write('notes: $notes, ')
          ..write('rating: $rating, ')
          ..write('replayDesire: $replayDesire, ')
          ..write('perceivedWeight: $perceivedWeight, ')
          ..write('winnerMemo: $winnerMemo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlaySessionExpansionsTable extends PlaySessionExpansions
    with TableInfo<$PlaySessionExpansionsTable, PlaySessionExpansion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaySessionExpansionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playSessionIdMeta = const VerificationMeta(
    'playSessionId',
  );
  @override
  late final GeneratedColumn<int> playSessionId = GeneratedColumn<int>(
    'play_session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES play_sessions (id)',
    ),
  );
  static const VerificationMeta _expansionGameKeyMeta = const VerificationMeta(
    'expansionGameKey',
  );
  @override
  late final GeneratedColumn<String> expansionGameKey = GeneratedColumn<String>(
    'expansion_game_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (game_key)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [playSessionId, expansionGameKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_session_expansions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaySessionExpansion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('play_session_id')) {
      context.handle(
        _playSessionIdMeta,
        playSessionId.isAcceptableOrUnknown(
          data['play_session_id']!,
          _playSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playSessionIdMeta);
    }
    if (data.containsKey('expansion_game_key')) {
      context.handle(
        _expansionGameKeyMeta,
        expansionGameKey.isAcceptableOrUnknown(
          data['expansion_game_key']!,
          _expansionGameKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expansionGameKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playSessionId, expansionGameKey};
  @override
  PlaySessionExpansion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaySessionExpansion(
      playSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_session_id'],
      )!,
      expansionGameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expansion_game_key'],
      )!,
    );
  }

  @override
  $PlaySessionExpansionsTable createAlias(String alias) {
    return $PlaySessionExpansionsTable(attachedDatabase, alias);
  }
}

class PlaySessionExpansion extends DataClass
    implements Insertable<PlaySessionExpansion> {
  final int playSessionId;
  final String expansionGameKey;
  const PlaySessionExpansion({
    required this.playSessionId,
    required this.expansionGameKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['play_session_id'] = Variable<int>(playSessionId);
    map['expansion_game_key'] = Variable<String>(expansionGameKey);
    return map;
  }

  PlaySessionExpansionsCompanion toCompanion(bool nullToAbsent) {
    return PlaySessionExpansionsCompanion(
      playSessionId: Value(playSessionId),
      expansionGameKey: Value(expansionGameKey),
    );
  }

  factory PlaySessionExpansion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaySessionExpansion(
      playSessionId: serializer.fromJson<int>(json['playSessionId']),
      expansionGameKey: serializer.fromJson<String>(json['expansionGameKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playSessionId': serializer.toJson<int>(playSessionId),
      'expansionGameKey': serializer.toJson<String>(expansionGameKey),
    };
  }

  PlaySessionExpansion copyWith({
    int? playSessionId,
    String? expansionGameKey,
  }) => PlaySessionExpansion(
    playSessionId: playSessionId ?? this.playSessionId,
    expansionGameKey: expansionGameKey ?? this.expansionGameKey,
  );
  PlaySessionExpansion copyWithCompanion(PlaySessionExpansionsCompanion data) {
    return PlaySessionExpansion(
      playSessionId: data.playSessionId.present
          ? data.playSessionId.value
          : this.playSessionId,
      expansionGameKey: data.expansionGameKey.present
          ? data.expansionGameKey.value
          : this.expansionGameKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionExpansion(')
          ..write('playSessionId: $playSessionId, ')
          ..write('expansionGameKey: $expansionGameKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playSessionId, expansionGameKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySessionExpansion &&
          other.playSessionId == this.playSessionId &&
          other.expansionGameKey == this.expansionGameKey);
}

class PlaySessionExpansionsCompanion
    extends UpdateCompanion<PlaySessionExpansion> {
  final Value<int> playSessionId;
  final Value<String> expansionGameKey;
  final Value<int> rowid;
  const PlaySessionExpansionsCompanion({
    this.playSessionId = const Value.absent(),
    this.expansionGameKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaySessionExpansionsCompanion.insert({
    required int playSessionId,
    required String expansionGameKey,
    this.rowid = const Value.absent(),
  }) : playSessionId = Value(playSessionId),
       expansionGameKey = Value(expansionGameKey);
  static Insertable<PlaySessionExpansion> custom({
    Expression<int>? playSessionId,
    Expression<String>? expansionGameKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playSessionId != null) 'play_session_id': playSessionId,
      if (expansionGameKey != null) 'expansion_game_key': expansionGameKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaySessionExpansionsCompanion copyWith({
    Value<int>? playSessionId,
    Value<String>? expansionGameKey,
    Value<int>? rowid,
  }) {
    return PlaySessionExpansionsCompanion(
      playSessionId: playSessionId ?? this.playSessionId,
      expansionGameKey: expansionGameKey ?? this.expansionGameKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playSessionId.present) {
      map['play_session_id'] = Variable<int>(playSessionId.value);
    }
    if (expansionGameKey.present) {
      map['expansion_game_key'] = Variable<String>(expansionGameKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionExpansionsCompanion(')
          ..write('playSessionId: $playSessionId, ')
          ..write('expansionGameKey: $expansionGameKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GamesTable games = $GamesTable(this);
  late final $CollectionEntriesTable collectionEntries =
      $CollectionEntriesTable(this);
  late final $BarcodeMapEntriesTable barcodeMapEntries =
      $BarcodeMapEntriesTable(this);
  late final $ApiCacheEntriesTable apiCacheEntries = $ApiCacheEntriesTable(
    this,
  );
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final $PlaySessionsTable playSessions = $PlaySessionsTable(this);
  late final $PlaySessionExpansionsTable playSessionExpansions =
      $PlaySessionExpansionsTable(this);
  late final Index collectionGameKeyIdx = Index(
    'collection_game_key_idx',
    'CREATE INDEX collection_game_key_idx ON collection (game_key)',
  );
  late final Index playSessionsGameKeyIdx = Index(
    'play_sessions_game_key_idx',
    'CREATE INDEX play_sessions_game_key_idx ON play_sessions (game_key)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    collectionEntries,
    barcodeMapEntries,
    apiCacheEntries,
    settingsEntries,
    playSessions,
    playSessionExpansions,
    collectionGameKeyIdx,
    playSessionsGameKeyIdx,
  ];
}

typedef $$GamesTableCreateCompanionBuilder =
    GamesCompanion Function({
      required String gameKey,
      Value<String?> bggId,
      Value<String?> localId,
      Value<String> gameKind,
      Value<String?> parentGameKey,
      required GameNames names,
      required String name,
      Value<String?> japaneseName,
      Value<String?> yearPublished,
      Value<int?> publisherMinPlayers,
      Value<int?> publisherMaxPlayers,
      Value<int?> playingTime,
      Value<int?> publisherMinAge,
      Value<String?> communityBestPlayers,
      Value<String?> communityRecommendedPlayers,
      Value<String?> communityMinAge,
      Value<SuggestedPlayerVotes> suggestedPlayerVotes,
      Value<String?> description,
      Value<String?> descriptionJa,
      Value<List<String>> mechanics,
      Value<List<String>> categories,
      Value<List<String>> designers,
      Value<List<String>> publishers,
      Value<String?> averageRating,
      Value<double?> weight,
      Value<GameRanks> ranks,
      Value<UpdateHistory> updateHistory,
      Value<String?> thumbnailUrl,
      Value<String?> rawYaml,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$GamesTableUpdateCompanionBuilder =
    GamesCompanion Function({
      Value<String> gameKey,
      Value<String?> bggId,
      Value<String?> localId,
      Value<String> gameKind,
      Value<String?> parentGameKey,
      Value<GameNames> names,
      Value<String> name,
      Value<String?> japaneseName,
      Value<String?> yearPublished,
      Value<int?> publisherMinPlayers,
      Value<int?> publisherMaxPlayers,
      Value<int?> playingTime,
      Value<int?> publisherMinAge,
      Value<String?> communityBestPlayers,
      Value<String?> communityRecommendedPlayers,
      Value<String?> communityMinAge,
      Value<SuggestedPlayerVotes> suggestedPlayerVotes,
      Value<String?> description,
      Value<String?> descriptionJa,
      Value<List<String>> mechanics,
      Value<List<String>> categories,
      Value<List<String>> designers,
      Value<List<String>> publishers,
      Value<String?> averageRating,
      Value<double?> weight,
      Value<GameRanks> ranks,
      Value<UpdateHistory> updateHistory,
      Value<String?> thumbnailUrl,
      Value<String?> rawYaml,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$GamesTableReferences
    extends BaseReferences<_$AppDatabase, $GamesTable, Game> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionEntriesTable, List<CollectionEntry>>
  _collectionEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectionEntries,
        aliasName: $_aliasNameGenerator(
          db.games.gameKey,
          db.collectionEntries.gameKey,
        ),
      );

  $$CollectionEntriesTableProcessedTableManager get collectionEntriesRefs {
    final manager =
        $$CollectionEntriesTableTableManager(
          $_db,
          $_db.collectionEntries,
        ).filter(
          (f) => f.gameKey.gameKey.sqlEquals($_itemColumn<String>('game_key')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _collectionEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BarcodeMapEntriesTable, List<BarcodeMapEntry>>
  _barcodeMapEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.barcodeMapEntries,
        aliasName: $_aliasNameGenerator(
          db.games.gameKey,
          db.barcodeMapEntries.gameKey,
        ),
      );

  $$BarcodeMapEntriesTableProcessedTableManager get barcodeMapEntriesRefs {
    final manager =
        $$BarcodeMapEntriesTableTableManager(
          $_db,
          $_db.barcodeMapEntries,
        ).filter(
          (f) => f.gameKey.gameKey.sqlEquals($_itemColumn<String>('game_key')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _barcodeMapEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaySessionsTable, List<PlaySession>>
  _playSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playSessions,
    aliasName: $_aliasNameGenerator(db.games.gameKey, db.playSessions.gameKey),
  );

  $$PlaySessionsTableProcessedTableManager get playSessionsRefs {
    final manager = $$PlaySessionsTableTableManager($_db, $_db.playSessions)
        .filter(
          (f) => f.gameKey.gameKey.sqlEquals($_itemColumn<String>('game_key')!),
        );

    final cache = $_typedResult.readTableOrNull(_playSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PlaySessionExpansionsTable,
    List<PlaySessionExpansion>
  >
  _playSessionExpansionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playSessionExpansions,
        aliasName: $_aliasNameGenerator(
          db.games.gameKey,
          db.playSessionExpansions.expansionGameKey,
        ),
      );

  $$PlaySessionExpansionsTableProcessedTableManager
  get playSessionExpansionsRefs {
    final manager =
        $$PlaySessionExpansionsTableTableManager(
          $_db,
          $_db.playSessionExpansions,
        ).filter(
          (f) => f.expansionGameKey.gameKey.sqlEquals(
            $_itemColumn<String>('game_key')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _playSessionExpansionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get gameKey => $composableBuilder(
    column: $table.gameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bggId => $composableBuilder(
    column: $table.bggId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameKind => $composableBuilder(
    column: $table.gameKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentGameKey => $composableBuilder(
    column: $table.parentGameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GameNames, GameNames, String> get names =>
      $composableBuilder(
        column: $table.names,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get japaneseName => $composableBuilder(
    column: $table.japaneseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get yearPublished => $composableBuilder(
    column: $table.yearPublished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get publisherMinPlayers => $composableBuilder(
    column: $table.publisherMinPlayers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get publisherMaxPlayers => $composableBuilder(
    column: $table.publisherMaxPlayers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playingTime => $composableBuilder(
    column: $table.playingTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get publisherMinAge => $composableBuilder(
    column: $table.publisherMinAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get communityBestPlayers => $composableBuilder(
    column: $table.communityBestPlayers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get communityRecommendedPlayers => $composableBuilder(
    column: $table.communityRecommendedPlayers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get communityMinAge => $composableBuilder(
    column: $table.communityMinAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    SuggestedPlayerVotes,
    SuggestedPlayerVotes,
    String
  >
  get suggestedPlayerVotes => $composableBuilder(
    column: $table.suggestedPlayerVotes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionJa => $composableBuilder(
    column: $table.descriptionJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get mechanics => $composableBuilder(
    column: $table.mechanics,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get designers => $composableBuilder(
    column: $table.designers,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GameRanks, GameRanks, String> get ranks =>
      $composableBuilder(
        column: $table.ranks,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<UpdateHistory, UpdateHistory, String>
  get updateHistory => $composableBuilder(
    column: $table.updateHistory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawYaml => $composableBuilder(
    column: $table.rawYaml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionEntriesRefs(
    Expression<bool> Function($$CollectionEntriesTableFilterComposer f) f,
  ) {
    final $$CollectionEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.collectionEntries,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEntriesTableFilterComposer(
            $db: $db,
            $table: $db.collectionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> barcodeMapEntriesRefs(
    Expression<bool> Function($$BarcodeMapEntriesTableFilterComposer f) f,
  ) {
    final $$BarcodeMapEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.barcodeMapEntries,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BarcodeMapEntriesTableFilterComposer(
            $db: $db,
            $table: $db.barcodeMapEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playSessionsRefs(
    Expression<bool> Function($$PlaySessionsTableFilterComposer f) f,
  ) {
    final $$PlaySessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaySessionsTableFilterComposer(
            $db: $db,
            $table: $db.playSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playSessionExpansionsRefs(
    Expression<bool> Function($$PlaySessionExpansionsTableFilterComposer f) f,
  ) {
    final $$PlaySessionExpansionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.gameKey,
          referencedTable: $db.playSessionExpansions,
          getReferencedColumn: (t) => t.expansionGameKey,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaySessionExpansionsTableFilterComposer(
                $db: $db,
                $table: $db.playSessionExpansions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get gameKey => $composableBuilder(
    column: $table.gameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bggId => $composableBuilder(
    column: $table.bggId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameKind => $composableBuilder(
    column: $table.gameKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentGameKey => $composableBuilder(
    column: $table.parentGameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get names => $composableBuilder(
    column: $table.names,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get japaneseName => $composableBuilder(
    column: $table.japaneseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get yearPublished => $composableBuilder(
    column: $table.yearPublished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get publisherMinPlayers => $composableBuilder(
    column: $table.publisherMinPlayers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get publisherMaxPlayers => $composableBuilder(
    column: $table.publisherMaxPlayers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playingTime => $composableBuilder(
    column: $table.playingTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get publisherMinAge => $composableBuilder(
    column: $table.publisherMinAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get communityBestPlayers => $composableBuilder(
    column: $table.communityBestPlayers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get communityRecommendedPlayers => $composableBuilder(
    column: $table.communityRecommendedPlayers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get communityMinAge => $composableBuilder(
    column: $table.communityMinAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestedPlayerVotes => $composableBuilder(
    column: $table.suggestedPlayerVotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionJa => $composableBuilder(
    column: $table.descriptionJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mechanics => $composableBuilder(
    column: $table.mechanics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get designers => $composableBuilder(
    column: $table.designers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ranks => $composableBuilder(
    column: $table.ranks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updateHistory => $composableBuilder(
    column: $table.updateHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawYaml => $composableBuilder(
    column: $table.rawYaml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get gameKey =>
      $composableBuilder(column: $table.gameKey, builder: (column) => column);

  GeneratedColumn<String> get bggId =>
      $composableBuilder(column: $table.bggId, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get gameKind =>
      $composableBuilder(column: $table.gameKind, builder: (column) => column);

  GeneratedColumn<String> get parentGameKey => $composableBuilder(
    column: $table.parentGameKey,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GameNames, String> get names =>
      $composableBuilder(column: $table.names, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get japaneseName => $composableBuilder(
    column: $table.japaneseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get yearPublished => $composableBuilder(
    column: $table.yearPublished,
    builder: (column) => column,
  );

  GeneratedColumn<int> get publisherMinPlayers => $composableBuilder(
    column: $table.publisherMinPlayers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get publisherMaxPlayers => $composableBuilder(
    column: $table.publisherMaxPlayers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playingTime => $composableBuilder(
    column: $table.playingTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get publisherMinAge => $composableBuilder(
    column: $table.publisherMinAge,
    builder: (column) => column,
  );

  GeneratedColumn<String> get communityBestPlayers => $composableBuilder(
    column: $table.communityBestPlayers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get communityRecommendedPlayers => $composableBuilder(
    column: $table.communityRecommendedPlayers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get communityMinAge => $composableBuilder(
    column: $table.communityMinAge,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SuggestedPlayerVotes, String>
  get suggestedPlayerVotes => $composableBuilder(
    column: $table.suggestedPlayerVotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionJa => $composableBuilder(
    column: $table.descriptionJa,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get mechanics =>
      $composableBuilder(column: $table.mechanics, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get categories =>
      $composableBuilder(
        column: $table.categories,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get designers =>
      $composableBuilder(column: $table.designers, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get publishers =>
      $composableBuilder(
        column: $table.publishers,
        builder: (column) => column,
      );

  GeneratedColumn<String> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GameRanks, String> get ranks =>
      $composableBuilder(column: $table.ranks, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UpdateHistory, String> get updateHistory =>
      $composableBuilder(
        column: $table.updateHistory,
        builder: (column) => column,
      );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawYaml =>
      $composableBuilder(column: $table.rawYaml, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> collectionEntriesRefs<T extends Object>(
    Expression<T> Function($$CollectionEntriesTableAnnotationComposer a) f,
  ) {
    final $$CollectionEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.gameKey,
          referencedTable: $db.collectionEntries,
          getReferencedColumn: (t) => t.gameKey,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectionEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectionEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> barcodeMapEntriesRefs<T extends Object>(
    Expression<T> Function($$BarcodeMapEntriesTableAnnotationComposer a) f,
  ) {
    final $$BarcodeMapEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.gameKey,
          referencedTable: $db.barcodeMapEntries,
          getReferencedColumn: (t) => t.gameKey,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BarcodeMapEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.barcodeMapEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> playSessionsRefs<T extends Object>(
    Expression<T> Function($$PlaySessionsTableAnnotationComposer a) f,
  ) {
    final $$PlaySessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaySessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.playSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playSessionExpansionsRefs<T extends Object>(
    Expression<T> Function($$PlaySessionExpansionsTableAnnotationComposer a) f,
  ) {
    final $$PlaySessionExpansionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.gameKey,
          referencedTable: $db.playSessionExpansions,
          getReferencedColumn: (t) => t.expansionGameKey,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaySessionExpansionsTableAnnotationComposer(
                $db: $db,
                $table: $db.playSessionExpansions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          Game,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (Game, $$GamesTableReferences),
          Game,
          PrefetchHooks Function({
            bool collectionEntriesRefs,
            bool barcodeMapEntriesRefs,
            bool playSessionsRefs,
            bool playSessionExpansionsRefs,
          })
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> gameKey = const Value.absent(),
                Value<String?> bggId = const Value.absent(),
                Value<String?> localId = const Value.absent(),
                Value<String> gameKind = const Value.absent(),
                Value<String?> parentGameKey = const Value.absent(),
                Value<GameNames> names = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> japaneseName = const Value.absent(),
                Value<String?> yearPublished = const Value.absent(),
                Value<int?> publisherMinPlayers = const Value.absent(),
                Value<int?> publisherMaxPlayers = const Value.absent(),
                Value<int?> playingTime = const Value.absent(),
                Value<int?> publisherMinAge = const Value.absent(),
                Value<String?> communityBestPlayers = const Value.absent(),
                Value<String?> communityRecommendedPlayers =
                    const Value.absent(),
                Value<String?> communityMinAge = const Value.absent(),
                Value<SuggestedPlayerVotes> suggestedPlayerVotes =
                    const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> descriptionJa = const Value.absent(),
                Value<List<String>> mechanics = const Value.absent(),
                Value<List<String>> categories = const Value.absent(),
                Value<List<String>> designers = const Value.absent(),
                Value<List<String>> publishers = const Value.absent(),
                Value<String?> averageRating = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<GameRanks> ranks = const Value.absent(),
                Value<UpdateHistory> updateHistory = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> rawYaml = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion(
                gameKey: gameKey,
                bggId: bggId,
                localId: localId,
                gameKind: gameKind,
                parentGameKey: parentGameKey,
                names: names,
                name: name,
                japaneseName: japaneseName,
                yearPublished: yearPublished,
                publisherMinPlayers: publisherMinPlayers,
                publisherMaxPlayers: publisherMaxPlayers,
                playingTime: playingTime,
                publisherMinAge: publisherMinAge,
                communityBestPlayers: communityBestPlayers,
                communityRecommendedPlayers: communityRecommendedPlayers,
                communityMinAge: communityMinAge,
                suggestedPlayerVotes: suggestedPlayerVotes,
                description: description,
                descriptionJa: descriptionJa,
                mechanics: mechanics,
                categories: categories,
                designers: designers,
                publishers: publishers,
                averageRating: averageRating,
                weight: weight,
                ranks: ranks,
                updateHistory: updateHistory,
                thumbnailUrl: thumbnailUrl,
                rawYaml: rawYaml,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String gameKey,
                Value<String?> bggId = const Value.absent(),
                Value<String?> localId = const Value.absent(),
                Value<String> gameKind = const Value.absent(),
                Value<String?> parentGameKey = const Value.absent(),
                required GameNames names,
                required String name,
                Value<String?> japaneseName = const Value.absent(),
                Value<String?> yearPublished = const Value.absent(),
                Value<int?> publisherMinPlayers = const Value.absent(),
                Value<int?> publisherMaxPlayers = const Value.absent(),
                Value<int?> playingTime = const Value.absent(),
                Value<int?> publisherMinAge = const Value.absent(),
                Value<String?> communityBestPlayers = const Value.absent(),
                Value<String?> communityRecommendedPlayers =
                    const Value.absent(),
                Value<String?> communityMinAge = const Value.absent(),
                Value<SuggestedPlayerVotes> suggestedPlayerVotes =
                    const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> descriptionJa = const Value.absent(),
                Value<List<String>> mechanics = const Value.absent(),
                Value<List<String>> categories = const Value.absent(),
                Value<List<String>> designers = const Value.absent(),
                Value<List<String>> publishers = const Value.absent(),
                Value<String?> averageRating = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<GameRanks> ranks = const Value.absent(),
                Value<UpdateHistory> updateHistory = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> rawYaml = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion.insert(
                gameKey: gameKey,
                bggId: bggId,
                localId: localId,
                gameKind: gameKind,
                parentGameKey: parentGameKey,
                names: names,
                name: name,
                japaneseName: japaneseName,
                yearPublished: yearPublished,
                publisherMinPlayers: publisherMinPlayers,
                publisherMaxPlayers: publisherMaxPlayers,
                playingTime: playingTime,
                publisherMinAge: publisherMinAge,
                communityBestPlayers: communityBestPlayers,
                communityRecommendedPlayers: communityRecommendedPlayers,
                communityMinAge: communityMinAge,
                suggestedPlayerVotes: suggestedPlayerVotes,
                description: description,
                descriptionJa: descriptionJa,
                mechanics: mechanics,
                categories: categories,
                designers: designers,
                publishers: publishers,
                averageRating: averageRating,
                weight: weight,
                ranks: ranks,
                updateHistory: updateHistory,
                thumbnailUrl: thumbnailUrl,
                rawYaml: rawYaml,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GamesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                collectionEntriesRefs = false,
                barcodeMapEntriesRefs = false,
                playSessionsRefs = false,
                playSessionExpansionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (collectionEntriesRefs) db.collectionEntries,
                    if (barcodeMapEntriesRefs) db.barcodeMapEntries,
                    if (playSessionsRefs) db.playSessions,
                    if (playSessionExpansionsRefs) db.playSessionExpansions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (collectionEntriesRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          CollectionEntry
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._collectionEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameKey == item.gameKey,
                              ),
                          typedResults: items,
                        ),
                      if (barcodeMapEntriesRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          BarcodeMapEntry
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._barcodeMapEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).barcodeMapEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameKey == item.gameKey,
                              ),
                          typedResults: items,
                        ),
                      if (playSessionsRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          PlaySession
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._playSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).playSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameKey == item.gameKey,
                              ),
                          typedResults: items,
                        ),
                      if (playSessionExpansionsRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          PlaySessionExpansion
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._playSessionExpansionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).playSessionExpansionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.expansionGameKey == item.gameKey,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      Game,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (Game, $$GamesTableReferences),
      Game,
      PrefetchHooks Function({
        bool collectionEntriesRefs,
        bool barcodeMapEntriesRefs,
        bool playSessionsRefs,
        bool playSessionExpansionsRefs,
      })
    >;
typedef $$CollectionEntriesTableCreateCompanionBuilder =
    CollectionEntriesCompanion Function({
      required String gameKey,
      Value<bool> owned,
      Value<String?> acquiredDate,
      Value<String?> condition,
      Value<String?> storageLocation,
      Value<String?> memo,
      Value<double?> purchasePrice,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CollectionEntriesTableUpdateCompanionBuilder =
    CollectionEntriesCompanion Function({
      Value<String> gameKey,
      Value<bool> owned,
      Value<String?> acquiredDate,
      Value<String?> condition,
      Value<String?> storageLocation,
      Value<String?> memo,
      Value<double?> purchasePrice,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CollectionEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectionEntriesTable,
          CollectionEntry
        > {
  $$CollectionEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameKeyTable(_$AppDatabase db) => db.games.createAlias(
    $_aliasNameGenerator(db.collectionEntries.gameKey, db.games.gameKey),
  );

  $$GamesTableProcessedTableManager get gameKey {
    final $_column = $_itemColumn<String>('game_key')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.gameKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionEntriesTable> {
  $$CollectionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get owned => $composableBuilder(
    column: $table.owned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acquiredDate => $composableBuilder(
    column: $table.acquiredDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameKey {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionEntriesTable> {
  $$CollectionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get owned => $composableBuilder(
    column: $table.owned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acquiredDate => $composableBuilder(
    column: $table.acquiredDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameKey {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionEntriesTable> {
  $$CollectionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get owned =>
      $composableBuilder(column: $table.owned, builder: (column) => column);

  GeneratedColumn<String> get acquiredDate => $composableBuilder(
    column: $table.acquiredDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameKey {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionEntriesTable,
          CollectionEntry,
          $$CollectionEntriesTableFilterComposer,
          $$CollectionEntriesTableOrderingComposer,
          $$CollectionEntriesTableAnnotationComposer,
          $$CollectionEntriesTableCreateCompanionBuilder,
          $$CollectionEntriesTableUpdateCompanionBuilder,
          (CollectionEntry, $$CollectionEntriesTableReferences),
          CollectionEntry,
          PrefetchHooks Function({bool gameKey})
        > {
  $$CollectionEntriesTableTableManager(
    _$AppDatabase db,
    $CollectionEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> gameKey = const Value.absent(),
                Value<bool> owned = const Value.absent(),
                Value<String?> acquiredDate = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> storageLocation = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionEntriesCompanion(
                gameKey: gameKey,
                owned: owned,
                acquiredDate: acquiredDate,
                condition: condition,
                storageLocation: storageLocation,
                memo: memo,
                purchasePrice: purchasePrice,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String gameKey,
                Value<bool> owned = const Value.absent(),
                Value<String?> acquiredDate = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> storageLocation = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionEntriesCompanion.insert(
                gameKey: gameKey,
                owned: owned,
                acquiredDate: acquiredDate,
                condition: condition,
                storageLocation: storageLocation,
                memo: memo,
                purchasePrice: purchasePrice,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectionEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameKey,
                                referencedTable:
                                    $$CollectionEntriesTableReferences
                                        ._gameKeyTable(db),
                                referencedColumn:
                                    $$CollectionEntriesTableReferences
                                        ._gameKeyTable(db)
                                        .gameKey,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CollectionEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionEntriesTable,
      CollectionEntry,
      $$CollectionEntriesTableFilterComposer,
      $$CollectionEntriesTableOrderingComposer,
      $$CollectionEntriesTableAnnotationComposer,
      $$CollectionEntriesTableCreateCompanionBuilder,
      $$CollectionEntriesTableUpdateCompanionBuilder,
      (CollectionEntry, $$CollectionEntriesTableReferences),
      CollectionEntry,
      PrefetchHooks Function({bool gameKey})
    >;
typedef $$BarcodeMapEntriesTableCreateCompanionBuilder =
    BarcodeMapEntriesCompanion Function({
      required String janCode,
      required String gameKey,
      required DateTime resolvedAt,
      required String source,
      Value<int> rowid,
    });
typedef $$BarcodeMapEntriesTableUpdateCompanionBuilder =
    BarcodeMapEntriesCompanion Function({
      Value<String> janCode,
      Value<String> gameKey,
      Value<DateTime> resolvedAt,
      Value<String> source,
      Value<int> rowid,
    });

final class $$BarcodeMapEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BarcodeMapEntriesTable,
          BarcodeMapEntry
        > {
  $$BarcodeMapEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameKeyTable(_$AppDatabase db) => db.games.createAlias(
    $_aliasNameGenerator(db.barcodeMapEntries.gameKey, db.games.gameKey),
  );

  $$GamesTableProcessedTableManager get gameKey {
    final $_column = $_itemColumn<String>('game_key')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.gameKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BarcodeMapEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BarcodeMapEntriesTable> {
  $$BarcodeMapEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get janCode => $composableBuilder(
    column: $table.janCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameKey {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BarcodeMapEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BarcodeMapEntriesTable> {
  $$BarcodeMapEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get janCode => $composableBuilder(
    column: $table.janCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameKey {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BarcodeMapEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BarcodeMapEntriesTable> {
  $$BarcodeMapEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get janCode =>
      $composableBuilder(column: $table.janCode, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameKey {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BarcodeMapEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BarcodeMapEntriesTable,
          BarcodeMapEntry,
          $$BarcodeMapEntriesTableFilterComposer,
          $$BarcodeMapEntriesTableOrderingComposer,
          $$BarcodeMapEntriesTableAnnotationComposer,
          $$BarcodeMapEntriesTableCreateCompanionBuilder,
          $$BarcodeMapEntriesTableUpdateCompanionBuilder,
          (BarcodeMapEntry, $$BarcodeMapEntriesTableReferences),
          BarcodeMapEntry,
          PrefetchHooks Function({bool gameKey})
        > {
  $$BarcodeMapEntriesTableTableManager(
    _$AppDatabase db,
    $BarcodeMapEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BarcodeMapEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BarcodeMapEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BarcodeMapEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> janCode = const Value.absent(),
                Value<String> gameKey = const Value.absent(),
                Value<DateTime> resolvedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BarcodeMapEntriesCompanion(
                janCode: janCode,
                gameKey: gameKey,
                resolvedAt: resolvedAt,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String janCode,
                required String gameKey,
                required DateTime resolvedAt,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => BarcodeMapEntriesCompanion.insert(
                janCode: janCode,
                gameKey: gameKey,
                resolvedAt: resolvedAt,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BarcodeMapEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameKey,
                                referencedTable:
                                    $$BarcodeMapEntriesTableReferences
                                        ._gameKeyTable(db),
                                referencedColumn:
                                    $$BarcodeMapEntriesTableReferences
                                        ._gameKeyTable(db)
                                        .gameKey,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BarcodeMapEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BarcodeMapEntriesTable,
      BarcodeMapEntry,
      $$BarcodeMapEntriesTableFilterComposer,
      $$BarcodeMapEntriesTableOrderingComposer,
      $$BarcodeMapEntriesTableAnnotationComposer,
      $$BarcodeMapEntriesTableCreateCompanionBuilder,
      $$BarcodeMapEntriesTableUpdateCompanionBuilder,
      (BarcodeMapEntry, $$BarcodeMapEntriesTableReferences),
      BarcodeMapEntry,
      PrefetchHooks Function({bool gameKey})
    >;
typedef $$ApiCacheEntriesTableCreateCompanionBuilder =
    ApiCacheEntriesCompanion Function({
      required String cacheKey,
      required String payload,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$ApiCacheEntriesTableUpdateCompanionBuilder =
    ApiCacheEntriesCompanion Function({
      Value<String> cacheKey,
      Value<String> payload,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$ApiCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ApiCacheEntriesTable> {
  $$ApiCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiCacheEntriesTable> {
  $$ApiCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiCacheEntriesTable> {
  $$ApiCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$ApiCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiCacheEntriesTable,
          ApiCacheEntry,
          $$ApiCacheEntriesTableFilterComposer,
          $$ApiCacheEntriesTableOrderingComposer,
          $$ApiCacheEntriesTableAnnotationComposer,
          $$ApiCacheEntriesTableCreateCompanionBuilder,
          $$ApiCacheEntriesTableUpdateCompanionBuilder,
          (
            ApiCacheEntry,
            BaseReferences<_$AppDatabase, $ApiCacheEntriesTable, ApiCacheEntry>,
          ),
          ApiCacheEntry,
          PrefetchHooks Function()
        > {
  $$ApiCacheEntriesTableTableManager(
    _$AppDatabase db,
    $ApiCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiCacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheEntriesCompanion(
                cacheKey: cacheKey,
                payload: payload,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String payload,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheEntriesCompanion.insert(
                cacheKey: cacheKey,
                payload: payload,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiCacheEntriesTable,
      ApiCacheEntry,
      $$ApiCacheEntriesTableFilterComposer,
      $$ApiCacheEntriesTableOrderingComposer,
      $$ApiCacheEntriesTableAnnotationComposer,
      $$ApiCacheEntriesTableCreateCompanionBuilder,
      $$ApiCacheEntriesTableUpdateCompanionBuilder,
      (
        ApiCacheEntry,
        BaseReferences<_$AppDatabase, $ApiCacheEntriesTable, ApiCacheEntry>,
      ),
      ApiCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsEntriesTableCreateCompanionBuilder =
    SettingsEntriesCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$SettingsEntriesTableUpdateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsEntriesTable,
          SettingsEntry,
          $$SettingsEntriesTableFilterComposer,
          $$SettingsEntriesTableOrderingComposer,
          $$SettingsEntriesTableAnnotationComposer,
          $$SettingsEntriesTableCreateCompanionBuilder,
          $$SettingsEntriesTableUpdateCompanionBuilder,
          (
            SettingsEntry,
            BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
          ),
          SettingsEntry,
          PrefetchHooks Function()
        > {
  $$SettingsEntriesTableTableManager(
    _$AppDatabase db,
    $SettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsEntriesTable,
      SettingsEntry,
      $$SettingsEntriesTableFilterComposer,
      $$SettingsEntriesTableOrderingComposer,
      $$SettingsEntriesTableAnnotationComposer,
      $$SettingsEntriesTableCreateCompanionBuilder,
      $$SettingsEntriesTableUpdateCompanionBuilder,
      (
        SettingsEntry,
        BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
      ),
      SettingsEntry,
      PrefetchHooks Function()
    >;
typedef $$PlaySessionsTableCreateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      required String gameKey,
      required String playedDate,
      Value<int?> playerCount,
      Value<int?> actualPlayingTime,
      Value<String?> notes,
      Value<int?> rating,
      Value<int?> replayDesire,
      Value<double?> perceivedWeight,
      Value<String?> winnerMemo,
      Value<DateTime> createdAt,
    });
typedef $$PlaySessionsTableUpdateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      Value<String> gameKey,
      Value<String> playedDate,
      Value<int?> playerCount,
      Value<int?> actualPlayingTime,
      Value<String?> notes,
      Value<int?> rating,
      Value<int?> replayDesire,
      Value<double?> perceivedWeight,
      Value<String?> winnerMemo,
      Value<DateTime> createdAt,
    });

final class $$PlaySessionsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaySessionsTable, PlaySession> {
  $$PlaySessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameKeyTable(_$AppDatabase db) => db.games.createAlias(
    $_aliasNameGenerator(db.playSessions.gameKey, db.games.gameKey),
  );

  $$GamesTableProcessedTableManager get gameKey {
    final $_column = $_itemColumn<String>('game_key')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.gameKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $PlaySessionExpansionsTable,
    List<PlaySessionExpansion>
  >
  _playSessionExpansionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playSessionExpansions,
        aliasName: $_aliasNameGenerator(
          db.playSessions.id,
          db.playSessionExpansions.playSessionId,
        ),
      );

  $$PlaySessionExpansionsTableProcessedTableManager
  get playSessionExpansionsRefs {
    final manager = $$PlaySessionExpansionsTableTableManager(
      $_db,
      $_db.playSessionExpansions,
    ).filter((f) => f.playSessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playSessionExpansionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playedDate => $composableBuilder(
    column: $table.playedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualPlayingTime => $composableBuilder(
    column: $table.actualPlayingTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replayDesire => $composableBuilder(
    column: $table.replayDesire,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get perceivedWeight => $composableBuilder(
    column: $table.perceivedWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerMemo => $composableBuilder(
    column: $table.winnerMemo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameKey {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playSessionExpansionsRefs(
    Expression<bool> Function($$PlaySessionExpansionsTableFilterComposer f) f,
  ) {
    final $$PlaySessionExpansionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playSessionExpansions,
          getReferencedColumn: (t) => t.playSessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaySessionExpansionsTableFilterComposer(
                $db: $db,
                $table: $db.playSessionExpansions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlaySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playedDate => $composableBuilder(
    column: $table.playedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualPlayingTime => $composableBuilder(
    column: $table.actualPlayingTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replayDesire => $composableBuilder(
    column: $table.replayDesire,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get perceivedWeight => $composableBuilder(
    column: $table.perceivedWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerMemo => $composableBuilder(
    column: $table.winnerMemo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameKey {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get playedDate => $composableBuilder(
    column: $table.playedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualPlayingTime => $composableBuilder(
    column: $table.actualPlayingTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get replayDesire => $composableBuilder(
    column: $table.replayDesire,
    builder: (column) => column,
  );

  GeneratedColumn<double> get perceivedWeight => $composableBuilder(
    column: $table.perceivedWeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get winnerMemo => $composableBuilder(
    column: $table.winnerMemo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameKey {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playSessionExpansionsRefs<T extends Object>(
    Expression<T> Function($$PlaySessionExpansionsTableAnnotationComposer a) f,
  ) {
    final $$PlaySessionExpansionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playSessionExpansions,
          getReferencedColumn: (t) => t.playSessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaySessionExpansionsTableAnnotationComposer(
                $db: $db,
                $table: $db.playSessionExpansions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlaySessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaySessionsTable,
          PlaySession,
          $$PlaySessionsTableFilterComposer,
          $$PlaySessionsTableOrderingComposer,
          $$PlaySessionsTableAnnotationComposer,
          $$PlaySessionsTableCreateCompanionBuilder,
          $$PlaySessionsTableUpdateCompanionBuilder,
          (PlaySession, $$PlaySessionsTableReferences),
          PlaySession,
          PrefetchHooks Function({bool gameKey, bool playSessionExpansionsRefs})
        > {
  $$PlaySessionsTableTableManager(_$AppDatabase db, $PlaySessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> gameKey = const Value.absent(),
                Value<String> playedDate = const Value.absent(),
                Value<int?> playerCount = const Value.absent(),
                Value<int?> actualPlayingTime = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<int?> replayDesire = const Value.absent(),
                Value<double?> perceivedWeight = const Value.absent(),
                Value<String?> winnerMemo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlaySessionsCompanion(
                id: id,
                gameKey: gameKey,
                playedDate: playedDate,
                playerCount: playerCount,
                actualPlayingTime: actualPlayingTime,
                notes: notes,
                rating: rating,
                replayDesire: replayDesire,
                perceivedWeight: perceivedWeight,
                winnerMemo: winnerMemo,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String gameKey,
                required String playedDate,
                Value<int?> playerCount = const Value.absent(),
                Value<int?> actualPlayingTime = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<int?> replayDesire = const Value.absent(),
                Value<double?> perceivedWeight = const Value.absent(),
                Value<String?> winnerMemo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlaySessionsCompanion.insert(
                id: id,
                gameKey: gameKey,
                playedDate: playedDate,
                playerCount: playerCount,
                actualPlayingTime: actualPlayingTime,
                notes: notes,
                rating: rating,
                replayDesire: replayDesire,
                perceivedWeight: perceivedWeight,
                winnerMemo: winnerMemo,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaySessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({gameKey = false, playSessionExpansionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playSessionExpansionsRefs) db.playSessionExpansions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (gameKey) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.gameKey,
                                    referencedTable:
                                        $$PlaySessionsTableReferences
                                            ._gameKeyTable(db),
                                    referencedColumn:
                                        $$PlaySessionsTableReferences
                                            ._gameKeyTable(db)
                                            .gameKey,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playSessionExpansionsRefs)
                        await $_getPrefetchedData<
                          PlaySession,
                          $PlaySessionsTable,
                          PlaySessionExpansion
                        >(
                          currentTable: table,
                          referencedTable: $$PlaySessionsTableReferences
                              ._playSessionExpansionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaySessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).playSessionExpansionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaySessionsTable,
      PlaySession,
      $$PlaySessionsTableFilterComposer,
      $$PlaySessionsTableOrderingComposer,
      $$PlaySessionsTableAnnotationComposer,
      $$PlaySessionsTableCreateCompanionBuilder,
      $$PlaySessionsTableUpdateCompanionBuilder,
      (PlaySession, $$PlaySessionsTableReferences),
      PlaySession,
      PrefetchHooks Function({bool gameKey, bool playSessionExpansionsRefs})
    >;
typedef $$PlaySessionExpansionsTableCreateCompanionBuilder =
    PlaySessionExpansionsCompanion Function({
      required int playSessionId,
      required String expansionGameKey,
      Value<int> rowid,
    });
typedef $$PlaySessionExpansionsTableUpdateCompanionBuilder =
    PlaySessionExpansionsCompanion Function({
      Value<int> playSessionId,
      Value<String> expansionGameKey,
      Value<int> rowid,
    });

final class $$PlaySessionExpansionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaySessionExpansionsTable,
          PlaySessionExpansion
        > {
  $$PlaySessionExpansionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaySessionsTable _playSessionIdTable(_$AppDatabase db) =>
      db.playSessions.createAlias(
        $_aliasNameGenerator(
          db.playSessionExpansions.playSessionId,
          db.playSessions.id,
        ),
      );

  $$PlaySessionsTableProcessedTableManager get playSessionId {
    final $_column = $_itemColumn<int>('play_session_id')!;

    final manager = $$PlaySessionsTableTableManager(
      $_db,
      $_db.playSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GamesTable _expansionGameKeyTable(_$AppDatabase db) =>
      db.games.createAlias(
        $_aliasNameGenerator(
          db.playSessionExpansions.expansionGameKey,
          db.games.gameKey,
        ),
      );

  $$GamesTableProcessedTableManager get expansionGameKey {
    final $_column = $_itemColumn<String>('expansion_game_key')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.gameKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expansionGameKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaySessionExpansionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaySessionExpansionsTable> {
  $$PlaySessionExpansionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlaySessionsTableFilterComposer get playSessionId {
    final $$PlaySessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playSessionId,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaySessionsTableFilterComposer(
            $db: $db,
            $table: $db.playSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GamesTableFilterComposer get expansionGameKey {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expansionGameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaySessionExpansionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaySessionExpansionsTable> {
  $$PlaySessionExpansionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlaySessionsTableOrderingComposer get playSessionId {
    final $$PlaySessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playSessionId,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaySessionsTableOrderingComposer(
            $db: $db,
            $table: $db.playSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GamesTableOrderingComposer get expansionGameKey {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expansionGameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaySessionExpansionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaySessionExpansionsTable> {
  $$PlaySessionExpansionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlaySessionsTableAnnotationComposer get playSessionId {
    final $$PlaySessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playSessionId,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaySessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.playSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GamesTableAnnotationComposer get expansionGameKey {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expansionGameKey,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.gameKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaySessionExpansionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaySessionExpansionsTable,
          PlaySessionExpansion,
          $$PlaySessionExpansionsTableFilterComposer,
          $$PlaySessionExpansionsTableOrderingComposer,
          $$PlaySessionExpansionsTableAnnotationComposer,
          $$PlaySessionExpansionsTableCreateCompanionBuilder,
          $$PlaySessionExpansionsTableUpdateCompanionBuilder,
          (PlaySessionExpansion, $$PlaySessionExpansionsTableReferences),
          PlaySessionExpansion,
          PrefetchHooks Function({bool playSessionId, bool expansionGameKey})
        > {
  $$PlaySessionExpansionsTableTableManager(
    _$AppDatabase db,
    $PlaySessionExpansionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaySessionExpansionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PlaySessionExpansionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaySessionExpansionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> playSessionId = const Value.absent(),
                Value<String> expansionGameKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaySessionExpansionsCompanion(
                playSessionId: playSessionId,
                expansionGameKey: expansionGameKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playSessionId,
                required String expansionGameKey,
                Value<int> rowid = const Value.absent(),
              }) => PlaySessionExpansionsCompanion.insert(
                playSessionId: playSessionId,
                expansionGameKey: expansionGameKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaySessionExpansionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playSessionId = false, expansionGameKey = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (playSessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.playSessionId,
                                    referencedTable:
                                        $$PlaySessionExpansionsTableReferences
                                            ._playSessionIdTable(db),
                                    referencedColumn:
                                        $$PlaySessionExpansionsTableReferences
                                            ._playSessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (expansionGameKey) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.expansionGameKey,
                                    referencedTable:
                                        $$PlaySessionExpansionsTableReferences
                                            ._expansionGameKeyTable(db),
                                    referencedColumn:
                                        $$PlaySessionExpansionsTableReferences
                                            ._expansionGameKeyTable(db)
                                            .gameKey,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PlaySessionExpansionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaySessionExpansionsTable,
      PlaySessionExpansion,
      $$PlaySessionExpansionsTableFilterComposer,
      $$PlaySessionExpansionsTableOrderingComposer,
      $$PlaySessionExpansionsTableAnnotationComposer,
      $$PlaySessionExpansionsTableCreateCompanionBuilder,
      $$PlaySessionExpansionsTableUpdateCompanionBuilder,
      (PlaySessionExpansion, $$PlaySessionExpansionsTableReferences),
      PlaySessionExpansion,
      PrefetchHooks Function({bool playSessionId, bool expansionGameKey})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$CollectionEntriesTableTableManager get collectionEntries =>
      $$CollectionEntriesTableTableManager(_db, _db.collectionEntries);
  $$BarcodeMapEntriesTableTableManager get barcodeMapEntries =>
      $$BarcodeMapEntriesTableTableManager(_db, _db.barcodeMapEntries);
  $$ApiCacheEntriesTableTableManager get apiCacheEntries =>
      $$ApiCacheEntriesTableTableManager(_db, _db.apiCacheEntries);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$PlaySessionsTableTableManager get playSessions =>
      $$PlaySessionsTableTableManager(_db, _db.playSessions);
  $$PlaySessionExpansionsTableTableManager get playSessionExpansions =>
      $$PlaySessionExpansionsTableTableManager(_db, _db.playSessionExpansions);
}
