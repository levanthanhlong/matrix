import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: MatrixDetApp(), debugShowCheckedModeBanner: false));
}

class MatrixDetApp extends StatefulWidget {
  const MatrixDetApp({super.key});

  @override
  State<MatrixDetApp> createState() => _MatrixDetAppState();
}

class _MatrixDetAppState extends State<MatrixDetApp> {
  int n = 3; // kích thước mặc định
  List<List<TextEditingController>> controllers = [];

  double? result;

  // allSteps lưu toàn bộ các bước (luôn hiển thị)
  List<Widget> allSteps = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    controllers = List.generate(n, (_) => List.generate(n, (_) => TextEditingController()));
  }

  void _changeSize(int newN) {
    setState(() {
      n = newN;
      _initControllers();
      result = null;
      allSteps.clear();
    });
  }

  // Tạo Widget hiển thị ma trận (dùng trong các bước)
  Widget _matrixWidget(List<List<double>> matrix) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        for (var row in matrix)
          TableRow(
            children: [
              for (var value in row)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(value.toStringAsFixed(6), textAlign: TextAlign.center),
                ),
            ],
          ),
      ],
    );
  }

  String _fmt(double v) => v.abs() < 1e-12 ? "0.000000" : v.toStringAsFixed(6);

  // Trả về một cặp (determinant, danh sách widget mô tả chi tiết từng bước)
  Map<String, dynamic> _generateDetailedSteps(List<List<double>> matrix) {
    int size = matrix.length;
    double det = 1.0;
    List<Widget> steps = [];

    List<List<double>> mat = List.generate(size, (i) => List.generate(size, (j) => matrix[i][j]));

    const double eps = 1e-12;

    steps.add(
      const Text(
        "Mục tiêu: Biến ma trận về dạng tam giác trên bằng phép biến đổi hàng (chỉ dùng phép cộng nhân hàng - không nhân hàng với số khác),và kết luận định thức bằng tích các phần tử trên đường chéo.",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    steps.add(const SizedBox(height: 6));

    steps.add(const Text("--- Kiến thức cốt lõi (tóm tắt) ---", style: TextStyle(fontWeight: FontWeight.bold)));
    steps.add(const Text("1) Định thức của ma trận vuông là một số đặc trưng cho tính khả nghịch và quy mô khối lượng tuyến tính."));
    steps.add(const Text("2) Các phép biến đổi hàng cơ bản ảnh hưởng đến định thức như sau:"));
    steps.add(const Text("   • Đổi hai hàng ↦ định thức đổi dấu (× -1)."));
    steps.add(const Text("   • Nhân một hàng với số c ≠ 0 ↦ định thức nhân thêm c."));
    steps.add(const Text("   • Cộng một bội của một hàng vào hàng khác ↦ định thức không đổi (chúng ta sử dụng phép này để khử)."));
    steps.add(
      const Text(
        "3) Do đó, nếu ta chỉ dùng phép 3 (cộng bội hàng khác), thì định thức không đổi; khi đổi hàng ta phải theo dõi dấu; khi nhân hàng (không dùng ở đây) phải điều chỉnh định thức.",
      ),
    );
    steps.add(const SizedBox(height: 8));

    steps.add(const Text("Ma trận đầu vào (chúng ta sao chép để không thay đổi dữ liệu gốc):"));
    steps.add(_matrixWidget(mat));
    steps.add(const SizedBox(height: 8));

    int swapCount = 0;

    for (int i = 0; i < size; i++) {
      // Tìm pivot (partial pivoting)
      int pivotRow = i;
      for (int r = i + 1; r < size; r++) {
        if (mat[r][i].abs() > mat[pivotRow][i].abs()) pivotRow = r;
      }

      steps.add(const SizedBox(height: 6));
      steps.add(
        Text("Bước ${i + 1}: chọn pivot tại cột ${i + 1} — hàng có trị tuyệt đối lớn nhất là ${pivotRow + 1} (giá trị = ${_fmt(mat[pivotRow][i])})."),
      );

      if (mat[pivotRow][i].abs() < eps) {
        steps.add(
          const Text(
            "Pivot ≈ 0 → cột này không độc lập ⇒ định thức = 0",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        );
        return {"det": 0.0, "steps": steps};
      }

      if (pivotRow != i) {
        var tmp = mat[i];
        mat[i] = mat[pivotRow];
        mat[pivotRow] = tmp;
        swapCount += 1;
        steps.add(Text("Đổi hàng ${i + 1} <-> hàng ${pivotRow + 1} vì pivot tốt hơn ở hàng ${pivotRow + 1}. Khi đổi hàng, định thức đổi dấu."));
        steps.add(_matrixWidget(mat));
      } else {
        steps.add(Text("Không cần đổi hàng (pivot ở hàng ${i + 1})."));
      }

      double pivot = mat[i][i];
      // Lưu pivot vào det. (Chú ý: vì ta không nhân hàng để đưa pivot về 1, mà giữ nguyên pivot và khử bằng factor, nên tích các pivot cho ra định thức (cần điều chỉnh dấu từ swapCount sau cùng)).
      det *= pivot;
      steps.add(Text("Pivot hiện tại = ${_fmt(pivot)} → nhân vào định thức tạm: ${_fmt(det)}"));

      // Khử các hàng dưới
      for (int j = i + 1; j < size; j++) {
        double factor = mat[j][i] / pivot;
        if (factor.abs() < eps) {
          steps.add(Text("Hàng ${j + 1}: phần tử dưới pivot là ${_fmt(mat[j][i])} → factor ≈ 0 → không cần khử."));
          continue;
        }

        steps.add(Text("Khử hàng ${j + 1}: factor = a(${j + 1},${i + 1}) / pivot = ${_fmt(mat[j][i])} / ${_fmt(pivot)} = ${_fmt(factor)}"));
        steps.add(Text("Cập nhật từng phần tử trong hàng (k từ ${i + 1} đến ${size}): a_jk := a_jk - factor * a_ik"));

        for (int k = i; k < size; k++) {
          double old = mat[j][k];
          double sub = factor * mat[i][k];
          double neu = old - sub;
          mat[j][k] = neu;
          steps.add(Text("a(${j + 1},${k + 1}): ${_fmt(old)} - ${_fmt(factor)}*${_fmt(mat[i][k])} = ${_fmt(neu)}"));
        }

        steps.add(const SizedBox(height: 4));
        steps.add(Text("Ma trận sau khi khử hàng ${j + 1}:"));
        steps.add(_matrixWidget(mat));
      }
    }

    // Điều chỉnh dấu nếu đổi hàng lẻ
    if (swapCount % 2 == 1) {
      det = -det;
      steps.add(const SizedBox(height: 6));
      steps.add(const Text("Số lần đổi hàng là số lẻ → định thức đổi dấu (nhân -1).", style: TextStyle(fontWeight: FontWeight.bold)));
    } else {
      steps.add(const SizedBox(height: 6));
      steps.add(const Text("Số lần đổi hàng là chẵn → định thức giữ dấu.", style: TextStyle(fontWeight: FontWeight.bold)));
    }

    steps.add(const SizedBox(height: 8));
    steps.add(const Text("Ma trận tam giác trên cuối cùng:"));
    steps.add(_matrixWidget(mat));
    steps.add(const SizedBox(height: 8));
    steps.add(Text("Kết luận: định thức = ${_fmt(det)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)));

    return {"det": det, "steps": steps};
  }

  void calculateDet() {
    // Lấy ma trận từ input người dùng
    List<List<double>> matrix = List.generate(n, (i) => List.generate(n, (j) => double.tryParse(controllers[i][j].text) ?? 0.0));

    // Chuẩn bị phần "Kiến thức cốt lõi" tóm tắt (để hiện ở đầu)
    List<Widget> core = [];
    core.add(const Text("=== KIẾN THỨC CỐT LÕI (Giải thích ngắn, dễ hiểu) ===", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
    core.add(const SizedBox(height: 6));
    core.add(
      const Text("• Định thức (det) là một số liên quan đến cách một ánh xạ tuyến tính co/giãn không gian; det = 0 ↔ ma trận không khả nghịch."),
    );
    core.add(
      const Text(
        "• Ta dùng biến đổi hàng để đưa ma trận về dạng tam giác trên. Việc cộng một bội của một hàng vào hàng khác KHÔNG làm thay đổi det — đây là phép biến đổi chính ta sử dụng để khử.",
      ),
    );
    core.add(
      const Text("• Khi đổi hai hàng thì det đổi dấu. Khi nhân một hàng với c thì det nhân c (chúng ta tránh nhân hàng để giữ công thức đơn giản)."),
    );
    core.add(const SizedBox(height: 8));

    // Ví dụ minh họa rõ ràng (cố định 3x3) — giúp người mới hình dung nhanh
    List<List<double>> sample = [
      [2, 1, 3],
      [4, 5, 6],
      [7, 8, 9],
    ];

    var sampleResult = _generateDetailedSteps(sample);

    // Tính cho ma trận người dùng
    var userResult = _generateDetailedSteps(matrix);

    setState(() {
      result = userResult['det'];

      // Ghép: core knowledge -> ví dụ minh họa -> kết quả ví dụ -> kết quả người dùng
      allSteps = [];
      allSteps.addAll(core);
      allSteps.add(const SizedBox(height: 6));
      allSteps.add(const Text('--- Ví dụ minh họa (ma trận 3×3):', style: TextStyle(fontWeight: FontWeight.bold)));
      allSteps.add(const SizedBox(height: 6));
      allSteps.add(const Text('Ma trận ví dụ:'));
      allSteps.add(_matrixWidget(sample));
      allSteps.add(const SizedBox(height: 6));
      allSteps.addAll(List<Widget>.from(sampleResult['steps']));

      allSteps.add(const SizedBox(height: 12));
      allSteps.add(const Text('--- Bây giờ tính cho ma trận của bạn:', style: TextStyle(fontWeight: FontWeight.bold)));
      allSteps.add(const SizedBox(height: 6));
      allSteps.add(const Text('Ma trận nhập:'));
      allSteps.add(_matrixWidget(matrix));
      allSteps.add(const SizedBox(height: 6));
      allSteps.addAll(List<Widget>.from(userResult['steps']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tính định thức ma trận — giải thích chi tiết")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Chọn kích thước ma trận: "),
                DropdownButton<int>(
                  value: n,
                  items: [for (int i = 2; i <= 10; i++) DropdownMenuItem(value: i, child: Text("${i}x$i"))],
                  onChanged: (val) => _changeSize(val!),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    for (int i = 0; i < n; i++)
                      TableRow(
                        children: [
                          for (int j = 0; j < n; j++)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: controllers[i][j],
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: calculateDet, child: const Text("Tính định thức")),
            const SizedBox(height: 10),

            // Luôn hiển thị toàn bộ bước (không còn chế độ step-by-step)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: allSteps.isEmpty
                    ? const Center(child: Text('Chưa có kết quả. Nhấn "Tính định thức" để bắt đầu.'))
                    : SingleChildScrollView(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: allSteps),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
