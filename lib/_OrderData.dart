class Order {
  final String company;
  final String service;
  final String date;
  final String time;
  final String address;

  Order({
    required this.company,
    required this.service,
    required this.date,
    required this.time,
    required this.address,
  });
}

// Global list of dummy orders (acts like a temporary database)
List<Order> pendingOrders = [];