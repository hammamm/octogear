class SellerCompany {
  const SellerCompany(this.id, this.name);
  final int id;
  final String name;
}

class SellerCompanyPage {
  const SellerCompanyPage(this.items, this.hasMore);
  final List<SellerCompany> items;
  final bool hasMore;
}
