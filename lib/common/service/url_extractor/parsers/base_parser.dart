class UrlMetadata {
  String? title;
  String? description;
  String? image;
  String? url;
  String? siteName;
  String? host;

  UrlMetadata({
    this.title,
    this.description,
    this.image,
    this.url,
    this.siteName,
    this.host,
  });

  factory UrlMetadata.fromJson(Map<String, dynamic> json) {
    return UrlMetadata(
      title: json['title'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      url: json['url'] as String?,
      siteName: json['siteName'] as String? ?? json['site_name'] as String?,
      host: json['host'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'image': image,
        'url': url,
        'siteName': siteName,
        'host': host,
      };
}

class BaseParser {}
