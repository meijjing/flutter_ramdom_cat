import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // main() 함수에서 async를 쓰려면 필요
  WidgetsFlutterBinding.ensureInitialized();

  // shared_preferences 인스턴스 생성
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CatService(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

/// 고양이 서비스
class CatService extends ChangeNotifier {
  // 고양이 사진 담을 변수
  List<String> catImages = [];
  // 좋아요 사진 담을 변수
  List<String> favoriteImages = [];
  // SharedPreferences 인스턴스
  SharedPreferences prefs;
  // 생성자(Constructor)
  CatService(this.prefs) {
    getRandomCatImages(); // api 호출
    favoriteImages = prefs.getStringList('favorites') ?? [];
  }

  bool showProgress = false;
  double progress = 0.2;

  void getRandomCatImages() async {
    const String url =
        'https://api.thecatapi.com/v1/images/search?limit=8&mime_types=jpg';
    showProgress = true;
    try {
      Response res = await Dio().get(url);
      for (int i = 0; i < res.data.length; i++) {
        var map = res.data[i];
        catImages.add(map['url']);
      }
      notifyListeners(); // 새로고침
    } catch (e) {
      print(e);
    } finally {}
    showProgress = false;
  }

  /// 좋아요 토글
  void toggleFavoriteImage(String catImage) {
    if (favoriteImages.contains(catImage)) {
      favoriteImages.remove(catImage);
    } else {
      favoriteImages.add(catImage);
    }
    prefs.setStringList('favorites', favoriteImages);
    notifyListeners(); // 새로고침
  }
}

/// 홈 페이지
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CatService>(
      builder: (context, catService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("랜덤 고양이"),
            backgroundColor: Colors.amber,
            actions: [
              // 좋아요 페이지로 이동
              IconButton(
                icon: Icon(Icons.favorite),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FavoritePage()),
                  );
                },
              )
            ],
          ),
          // 고양이 사진 목록
          body: catService.showProgress
              ? Center(child: CircularProgressIndicator(value: 0.2))
              : GridView.count(
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: EdgeInsets.all(8),
                  crossAxisCount: 2,
                  children: List.generate(
                    catService.catImages.length,
                    (index) {
                      String catImg = catService.catImages[index];
                      return GestureDetector(
                        onTap: () {
                          catService.toggleFavoriteImage(catImg);
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(catImg, fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Icon(Icons.favorite,
                                  color:
                                      catService.favoriteImages.contains(catImg)
                                          ? Color.fromARGB(255, 255, 168, 28)
                                          : Colors.transparent),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

/// 좋아요 페이지
class FavoritePage extends StatelessWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CatService>(
      builder: (context, catService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("좋아요"),
            backgroundColor: Colors.amber,
          ),
          // 고양이 사진 목록
          body: GridView.count(
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: EdgeInsets.all(8),
            crossAxisCount: 2,
            children: List.generate(
              catService.favoriteImages.length,
              (index) {
                String catImg = catService.favoriteImages[index];
                return GestureDetector(
                  onTap: () {
                    print('click $index');
                  },
                  child: Image.network(catImg, fit: BoxFit.cover),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
