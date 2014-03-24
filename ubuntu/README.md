#Mô Hình
Mô hình kết nối như sau:
- Controll node: 2 interface (1 manager, 1 exten để cài đặt các gói tin)
- Network node: 3 interface (1 manager, 1 exten, 1 tunneling)
- Computer node: 3 interface (1 manager, 1 exten để cài đặt, 1 tunneling)
1. Cần có 1 card manager kết nối giữa 3 con.
2. Cần 1 card để cài đặt các gói tin.
3. Cần 1 card để kết nối giữa computer node với network node

# Sử dụng 3 bộ shell all để cài đặt riêng cho từng con.