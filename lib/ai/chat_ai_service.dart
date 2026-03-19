String getChatResponse(String text) {
  if (text.contains('ازيك')) {
    return 'انا تمام، تحب أساعدك في إيه؟';
  }

  if (text.contains('عامل ايه')) {
    return 'أنا بخير الحمد لله.';
  }

  if (text.contains('نكتة')) {
    return 'مرة مبرمج دخل مطعم طلب كود بدل الأكل!';
  }

  return 'ممكن توضح طلبك؟';
}
