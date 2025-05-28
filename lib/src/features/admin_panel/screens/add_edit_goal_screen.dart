import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import '../../../core/models/goal_model.dart';
import '../../../core/services/goal_service.dart';
import 'dart:math'; // For random ID
import 'package:flutter/material.dart'; // Already present, but good to note
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/models/article_model.dart'; // Import Article model
import '../../../core/models/goal_model.dart'; // Already present
import '../../../core/services/goal_service.dart'; // Already present


class AddEditGoalScreen extends StatefulWidget {
  final Goal? goalToEdit;

  const AddEditGoalScreen({super.key, this.goalToEdit});

  @override
  _AddEditGoalScreenState createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final GoalService _goalService = GoalService();

  String _name = '';
  double _targetAmount = 0.0;
  String _paypalEmail = '';
  List<Article> _articles = []; // State for managing articles

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _name = widget.goalToEdit!.name;
      _targetAmount = widget.goalToEdit!.targetAmount;
      _paypalEmail = widget.goalToEdit!.paypalEmail ?? '';
      _articles = List<Article>.from(
        widget.goalToEdit!.articles,
      ); // Initialize articles
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (widget.goalToEdit != null) {
        // Update existing goal
        final updatedGoal = widget.goalToEdit!.copyWith(
          name: _name,
          targetAmount: _targetAmount,
          paypalEmail: _paypalEmail.isNotEmpty ? _paypalEmail : null,
          articles: _articles,
        );
        _goalService.updateGoal(updatedGoal);
      } else {
        // Add new goal
        String id =
            DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(99999).toString();
        final newGoal = Goal(
          id: id,
          name: _name,
          targetAmount: _targetAmount,
          paypalEmail: _paypalEmail.isNotEmpty ? _paypalEmail : null,
          articles: _articles,
        );
        _goalService.addGoal(newGoal);
      }

      Navigator.pop(
        context,
        true,
      ); // Return true to indicate a goal was added/changed
    }
  }

  void _addOrEditArticleDialog({Article? articleToEdit, int? articleIndex}) {
    final articleFormKey = GlobalKey<FormState>();
    String articleName = articleToEdit?.name ?? '';
    double articlePrice = articleToEdit?.price ?? 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(articleToEdit == null ? 'Add Article' : 'Edit Article'),
          content: Form(
            key: articleFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  initialValue: articleName,
                  decoration: InputDecoration(labelText: 'Article Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter article name';
                    }
                    return null;
                  },
                  onSaved: (value) => articleName = value!,
                ),
                TextFormField(
                  initialValue: articlePrice.toStringAsFixed(2),
                  decoration: InputDecoration(labelText: 'Price (€)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid positive price';
                    }
                    return null;
                  },
                  onSaved: (value) => articlePrice = double.parse(value!),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(articleToEdit == null ? 'Add' : 'Save'),
              onPressed: () {
                if (articleFormKey.currentState!.validate()) {
                  articleFormKey.currentState!.save();
                  setState(() {
                    if (articleToEdit == null) {
                      // Add new
                      _articles.add(
                        Article(
                          id:
                              DateTime.now().millisecondsSinceEpoch.toString() +
                              Random()
                                  .nextInt(1000)
                                  .toString(), // Simple unique ID for client-side list
                          name: articleName,
                          price: articlePrice,
                        ),
                      );
                    } else {
                      // Edit existing
                      if (articleIndex != null) {
                        _articles[articleIndex] = articleToEdit.copyWith(
                          name: articleName,
                          price: articlePrice,
                        );
                      }
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalToEdit == null ? 'Add New Goal' : 'Edit Goal'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Use ListView to prevent overflow on smaller screens
            children: <Widget>[
              TextFormField(
                initialValue: _name, // Set initial value
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              SizedBox(height: 20),
              TextFormField(
                initialValue: _targetAmount > 0
                    ? _targetAmount.toStringAsFixed(2)
                    : '', // Set initial value
                decoration: InputDecoration(
                  labelText: 'Target Amount (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro_symbol), // Changed icon
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
                onSaved: (value) => _targetAmount = double.parse(value!),
              ),
              SizedBox(height: 20),
              TextFormField(
                initialValue: _paypalEmail, // Set initial value
                decoration: InputDecoration(
                  labelText: 'PayPal Email (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                // No validator needed for optional field, unless specific format is required when present
                onSaved: (value) => _paypalEmail = value ?? '',
              ),
              SizedBox(height: 20),
              Divider(thickness: 1.5),
              SizedBox(height: 10),
              Text(
                'Articles / Items for this Goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 10),
              _articles.isEmpty
                  ? Center(
                      child: Text(
                        'No articles added yet. Click "Add Article" to start.',
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics:
                          NeverScrollableScrollPhysics(), // To use inside another ListView
                      itemCount: _articles.length,
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(article.name),
                            subtitle: Text(
                              'Price: €${article.price.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blueGrey,
                                  ),
                                  onPressed: () => _addOrEditArticleDialog(
                                    articleToEdit: article,
                                    articleIndex: index,
                                  ),
                                  tooltip: 'Edit Article',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _articles.removeAt(index);
                                    });
                                  },
                                  tooltip: 'Remove Article',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              SizedBox(height: 10),
              OutlinedButton.icon(
                icon: Icon(Icons.add_shopping_cart_outlined),
                label: Text('Add Article'),
                onPressed: () => _addOrEditArticleDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurpleAccent,
                  side: BorderSide(color: Colors.deepPurpleAccent),
                ),
              ),
              SizedBox(height: 10), // Added space
              OutlinedButton.icon(
                icon: Icon(Icons.document_scanner_outlined),
                label: Text('Scan Articles from Image'),
                onPressed: _scanImageForArticles,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(color: Colors.orangeAccent),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  widget.goalToEdit == null ? 'Save New Goal' : 'Update Goal',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Article> _parseTextToArticles(RecognizedText recognizedText) {
    final List<Article> articles = [];
    final List<String> lines = recognizedText.text.split('\n').map((line) => line.trim()).toList();
    List<String> namePartsBuffer = [];

    // Regex refined:
    // Group 1: Optional currency symbol at the start
    // Group 2: The numeric price part (allows for ., as thousands/decimal)
    // Group 3: Optional currency symbol at the end
    // Handles: $10.99, 10.99€, 1,234.56, 1.234,56, 10, 10.00
    final RegExp priceAtEndRegex = RegExp(
        r'([€\$£]?\s*\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})|\d+(?:[.,]\d{1,2})?)\s*([€\$£]|USD|EUR)?\s*$',
        caseSensitive: false);
    // Regex for lines that are predominantly a price (or quantity like "2x")
    final RegExp lineIsMostlyPriceOrQtyRegex = RegExp(
        r'^\s*([€\$£]?\s*\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})|\d+(?:[.,]\d{1,2})?)\s*([€\$£]|USD|EUR)?\s*$|^\s*\d+\s*(?:x|X)\s*$',
        caseSensitive: false);
    
    final List<String> nonItemKeywords = [
      'TOTAL', 'SUBTOTAL', 'TAX', 'VAT', 'CASH', 'CARD', 'CHANGE', 'PAYMENT',
      'DISCOUNT', 'SERVICE', 'CHARGE', 'TIP', 'BALANCE', 'RECEIPT', 'INVOICE', 
      'ORDER', 'SERVER', 'CLERK', 'DATE', 'TIME', 'PHONE', 'WEBSITE', 'TABLE', 'GUEST',
      'ITEMS', 'ITEM', 'QTY', 'SUB TOTAL', 'GST', 'PST', 'HST'
    ];

    double? parsePrice(String priceStr) {
      String p = priceStr.replaceAll(RegExp(r'[€\$£A-Za-z\s]'), ''); // Remove symbols & letters
      int lastDot = p.lastIndexOf('.');
      int lastComma = p.lastIndexOf(',');

      if (lastDot > lastComma) { // Decimal is '.', thousands is ',' (e.g., 1,234.56)
        p = p.replaceAll(',', '');
      } else if (lastComma > lastDot) { // Decimal is ',', thousands is '.' (e.g., 1.234,56)
        p = p.replaceAll('.', '').replaceAll(',', '.');
      } else { // No thousands, or only one type of separator
        p = p.replaceAll(',', '.'); // Assume comma is decimal if no dot, or if it's the only one
      }
      return double.tryParse(p);
    }

    for (String currentLine in lines) {
      if (currentLine.isEmpty) {
        if (namePartsBuffer.isNotEmpty) { // If there was a name buffered, but no price followed
            namePartsBuffer.clear(); // Discard it to prevent it from attaching to a far-off price
        }
        continue;
      }

      // Filter out lines that are likely headers/footers/noise
      bool isKeywordLine = nonItemKeywords.any((kw) => currentLine.toUpperCase().contains(kw) && currentLine.length < kw.length + 15);
      if (isKeywordLine) {
          namePartsBuffer.clear(); // This line is likely not part of an item name.
          continue;
      }

      Match? priceMatch = priceAtEndRegex.firstMatch(currentLine);
      
      if (priceMatch != null) {
        String potentialPriceStr = priceMatch.group(1)!;
        double? price = parsePrice(potentialPriceStr);

        if (price != null && price > 0) {
          String potentialName = currentLine.substring(0, priceMatch.start).trim();
          potentialName = potentialName.replaceAll(RegExp(r'\s*\d+\s*(?:x|X)\s*$'), '').trim(); // Remove " 2x" from end of name

          if (potentialName.isNotEmpty) {
            if (namePartsBuffer.isNotEmpty) {
              potentialName = namePartsBuffer.join(' ') + ' ' + potentialName;
              namePartsBuffer.clear();
            }
            articles.add(Article(id: 'scan_${articles.length}', name: potentialName, price: price));
          } else if (namePartsBuffer.isNotEmpty) { 
            // Price is on its own line, name was in buffer
            articles.add(Article(id: 'scan_${articles.length}', name: namePartsBuffer.join(' '), price: price));
            namePartsBuffer.clear();
          }
          // else: price found but no name, could be a sub-price or tax, ignore for now
          continue; // Line processed
        }
      }
      
      // If no price was found on this line, or if a price was found but no name could be associated yet
      // (e.g. price was at the start of the line), add current line to name buffer.
      if (!lineIsMostlyPriceOrQtyRegex.hasMatch(currentLine)) {
          if (namePartsBuffer.length < 3) { // Limit name parts to avoid overly long names
            namePartsBuffer.add(currentLine);
          } else { // Buffer too long, likely not a multi-line name, discard old parts.
            namePartsBuffer.clear();
            namePartsBuffer.add(currentLine);
          }
      } else if (namePartsBuffer.isNotEmpty && lineIsMostlyPriceOrQtyRegex.hasMatch(currentLine)) {
          // Current line is just a price/qty, but there was a name part before it.
          // This is handled by the next iteration if a price is found, or namePartsBuffer will be cleared.
          // However, if this is the *last* line, we might miss it.
          // This case is complex, for now, we rely on price being associated with name parts when price is found.
      } else {
          namePartsBuffer.clear(); // Line is just price/qty, and no preceding name parts.
      }
    }
    return articles.where((art) => art.name.length > 2 && art.price > 0).toList();
  }

  void _showConfirmScannedArticlesDialog(List<Article> scannedArticles) {
    List<Article> articlesToConfirm = List.from(
      scannedArticles.map(
        (art) => Article(
          id: art.id, // Keep temp ID for now
          name: art.name,
          price: art.price,
        ),
      ),
    );

    // Need to use a GlobalKey for each TextFormField if we want to read their values
    // directly, or manage changes with TextEditingControllers.
    // For simplicity with onChanged, ensure Article has a working copyWith or fields are mutable.
    // For this example, we'll rely on updating the list directly via onChanged and article.copyWith.

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text("Confirm Scanned Articles"),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: articlesToConfirm.length,
                itemBuilder: (itemContext, index) {
                  Article article = articlesToConfirm[index];
                  // It's better to use TextEditingControllers for real forms
                  // For this example, we'll update a temporary list of Article objects
                  // by creating new Article instances on change if Article is immutable.
                  // If Article is mutable, we could change its properties directly.
                  // Let's assume Article has a copyWith for this example.

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: article.name,
                                  decoration: InputDecoration(labelText: "Name"),
                                  onChanged: (newName) {
                                    // If Article is immutable with copyWith:
                                    articlesToConfirm[index] = article.copyWith(name: newName);
                                    // If Article is mutable:
                                    // article.name = newName;
                                    // setDialogState(() {}); // May not be needed if using controllers
                                  },
                                ),
                                TextFormField(
                                  initialValue: article.price.toStringAsFixed(2),
                                  decoration: InputDecoration(labelText: "Price (€)"),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  onChanged: (newPrice) {
                                    // If Article is immutable with copyWith:
                                     articlesToConfirm[index] = article.copyWith(price: double.tryParse(newPrice) ?? article.price);
                                    // If Article is mutable:
                                    // article.price = double.tryParse(newPrice) ?? article.price;
                                    // setDialogState(() {}); // May not be needed
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              setDialogState(() {
                                articlesToConfirm.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text("Add to Goal"),
                onPressed: () {
                  setState(() { // This is _AddEditGoalScreenState.setState
                    _articles.addAll(articlesToConfirm.map(
                      (art) => Article(
                        id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(99999).toString(), // New unique ID
                        name: art.name,
                        price: art.price,
                      ),
                    ));
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }


  Future<void> _scanImageForArticles() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imageFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (imageFile == null) return; // User cancelled

      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (!mounted) return;

      List<Article> parsedArticles = _parseTextToArticles(recognizedText);
      if (parsedArticles.isEmpty && recognizedText.text.isNotEmpty) {
         // If parsing failed but text was found, show raw text as fallback
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("OCR - No Articles Parsed (Raw Text)"),
            content: SingleChildScrollView(child: Text(recognizedText.text)),
            actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("OK")) ],
          ),
        );
      } else if (parsedArticles.isNotEmpty) {
        _showConfirmScannedArticlesDialog(parsedArticles);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No text found in the image.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning image: ${e.toString()}')),
      );
    }
  }
}
