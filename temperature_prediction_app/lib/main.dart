import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Climate Predictor',
      theme: ThemeData(
        primaryColor: Color(0xFF0A1F44),
        scaffoldBackgroundColor: Color(0xFFFFC0CB),
      ),
      home: PredictionPage(),
    );
  }
}
class PredictionPage extends StatefulWidget {
  @override
  _PredictionPageState createState() => _PredictionPageState();
}
class _PredictionPageState extends State<PredictionPage> {
  final co2Controller = TextEditingController();
  final seaLevelController = TextEditingController();
  final rainfallController = TextEditingController();
  final populationController = TextEditingController();
  final renewableController = TextEditingController();
  final extremeWeatherController = TextEditingController();
  final forestController = TextEditingController();

  String result = "";
  bool isLoading = false;

  double? safeDouble(String value) => double.tryParse(value);
  int? safeInt(String value) => int.tryParse(value);

  Future<void> predict() async {
    final co2 = safeDouble(co2Controller.text);
    final sea = safeDouble(seaLevelController.text);
    final rain = safeDouble(rainfallController.text);
    final pop = safeInt(populationController.text);
    final ren = safeDouble(renewableController.text);
    final extreme = safeInt(extremeWeatherController.text);
    final forest = safeDouble(forestController.text);

    if ([co2, sea, rain, pop, ren, extreme, forest].contains(null)) {
      setState(() {
        result = "Please enter valid numbers in all fields";
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
    });

    final url = Uri.parse("https://temperature-prediction-j6aq.onrender.com/predict");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "CO2": co2,
          "Sea_Level": sea,
          "Rainfall": rain,
          "Population": pop,
          "Renewable": ren,
          "Extreme_Weather": extreme,
          "Forest": forest,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = "🌡 Predicted Temperature: ${data['predicted_temperature'].toStringAsFixed(2)} °C";
        });
      } else {
        setState(() {
          result = "Server error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        result = " Error: $e";
      });
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Widget buildTextField(String label, String unit, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "$label ($unit)",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Climate Predictor", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF0A1F44),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildTextField("CO2 Emissions", "tons/capita", co2Controller),
                buildTextField("Sea Level Rise", "mm", seaLevelController),
                buildTextField("Rainfall", "mm", rainfallController),
                buildTextField("Population", "people", populationController),
                buildTextField("Renewable Energy", "%", renewableController),
                buildTextField("Extreme Weather Events", "count", extremeWeatherController),
                buildTextField("Forest Area", "%", forestController),

                SizedBox(height: 20),

                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: predict,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0A1F44),
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Predict", style: TextStyle(fontSize: 18)),
                      ),

                SizedBox(height: 20),

                Text(
                  result,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
