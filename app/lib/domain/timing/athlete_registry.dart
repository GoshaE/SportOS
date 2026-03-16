/// Реестр предзарегистрированных спортсменов.
///
/// Используется для демо — можно выбрать и добавить в гонку.
/// В будущем заменится на загрузку из БД / API.
class AthleteRegistry {
  AthleteRegistry._();

  /// Предзарегистрированные спортсмены.
  static const List<({String entryId, String bib, String name, String category})> athletes = [
    (entryId: 'r01', bib: '01', name: 'Петров Алексей', category: 'Скиджоринг'),
    (entryId: 'r02', bib: '05', name: 'Сидоров Борис', category: 'Скиджоринг'),
    (entryId: 'r03', bib: '10', name: 'Иванов Виктор', category: 'Нарты'),
    (entryId: 'r04', bib: '14', name: 'Козлов Георгий', category: 'Нарты'),
    (entryId: 'r05', bib: '19', name: 'Морозов Дмитрий', category: 'Скиджоринг'),
    (entryId: 'r06', bib: '23', name: 'Волков Евгений', category: 'Пулка'),
    (entryId: 'r07', bib: '28', name: 'Лебедев Сергей', category: 'Скиджоринг'),
    (entryId: 'r08', bib: '33', name: 'Новиков Захар', category: 'Нарты'),
    (entryId: 'r09', bib: '37', name: 'Кузнецов Павел', category: 'Скиджоринг'),
    (entryId: 'r10', bib: '42', name: 'Соколов Роман', category: 'Каникросс'),
  ];
}
