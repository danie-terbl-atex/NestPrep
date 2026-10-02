/// Where a Checkers product's picture is served, at the size a match row
/// shows it. Public and unauthenticated, like the catalogue search.
Uri checkersImageUrl(String imageId) => Uri.https(
  'catalog.sixty60.co.za',
  '/v2/files/$imageId',
  const {'width': '300', 'height': '300'},
);
