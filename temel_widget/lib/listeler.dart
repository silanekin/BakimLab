void main()
{
  List<String> urunler = [];
  urunler.add("Laptop");
  urunler.add("Mouse");
  urunler.add("Keyboard");
  urunler.add("Monitor");
  urunler.add("Mic");



  print(urunler.where((s)=>s.contains("a")));
  print(urunler[2]);

}