/// Model địa điểm du lịch Đà Lạt
class PlaceItem {
  final String id;
  final String title;
  final double rating;
  final String reviewCount;
  final String category;
  final String price;
  final String distance;
  final String image;
  final String description;
  final bool isFavorite;

  const PlaceItem({
    required this.id,
    required this.title,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.price,
    required this.distance,
    required this.image,
    required this.description,
    this.isFavorite = false,
  });
}

/// Dữ liệu mẫu các địa điểm nổi tiếng theo đúng thiết kế
class TravelData {
  static const List<PlaceItem> samplePlaces = [
    PlaceItem(
      id: 'p1',
      title: 'Hồ Tuyền Lâm',
      rating: 4.6,
      reviewCount: '12.3k',
      category: 'Thiên nhiên',
      price: 'Miễn phí',
      distance: '5.2 km',
      image: 'assets/images/places/ho_tuyen_lam.webp',
      description:
          'Hồ Tuyền Lâm là một trong những địa điểm du lịch nổi tiếng nhất tại Đà Lạt, với khung cảnh thiên nhiên thơ mộng, hồ nước trong xanh bao quanh bởi những đồi thông xanh ngát.',
      isFavorite: true,
    ),
    PlaceItem(
      id: 'p2',
      title: 'Ga Đà Lạt',
      rating: 4.4,
      reviewCount: '8.1k',
      category: 'Văn hoá',
      price: '50.000đ',
      distance: '1.8 km',
      image: 'assets/images/places/ga_da_lat.webp',
      description:
          'Nhà ga xe lửa cổ kính nhất Đông Dương mang phong cách kiến trúc Pháp độc đáo với 3 mái chóp hình đỉnh núi Langbiang hùng vĩ.',
      isFavorite: true,
    ),
    PlaceItem(
      id: 'p3',
      title: 'Đồi chè Cầu Đất',
      rating: 4.5,
      reviewCount: '9.4k',
      category: 'Check-in',
      price: 'Miễn phí',
      distance: '24 km',
      image: 'assets/images/places/doi_che_cau_dat.webp',
      description:
          'Không gian bạt ngàn màu xanh của những đồi chè tuổi đời gần 100 năm, điểm săn mây và đón bình minh đẹp bậc nhất xứ ngàn hoa.',
      isFavorite: true,
    ),
    PlaceItem(
      id: 'p4',
      title: 'Thung lũng Tình Yêu',
      rating: 4.3,
      reviewCount: '7.2k',
      category: 'Tham quan',
      price: '100.000đ',
      distance: '3.6 km',
      image: 'assets/images/places/thung_lung_tinh_yeu.webp',
      description:
          'Khu du lịch sinh thái nổi tiếng với cảnh quan lãng mạn, mê cung tình yêu, hồ Đa Thiện và những khu vườn hoa rực rỡ.',
      isFavorite: false,
    ),
    PlaceItem(
      id: 'p5',
      title: 'The Diff House',
      rating: 4.6,
      reviewCount: '6.2k',
      category: 'Cafe view đẹp',
      price: '50.000đ - 150.000đ',
      distance: '6.2 km',
      image: 'assets/images/dalat_glasshouse.jpg',
      description:
          'Quán cafe trên mây độc đáo với tầm nhìn toàn cảnh thung lũng thông reo và biển mây bồng bềnh mỗi sớm mai.',
      isFavorite: true,
    ),
  ];
}
