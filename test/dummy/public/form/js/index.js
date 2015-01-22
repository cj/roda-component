function initTricks() {
    var labels = $('.floating-placeholder label');
    labels.each(function(i) {
        var ph = $(labels[i])
            .siblings('input')
            .first()
            .attr('placeholder');
        $(labels[i]).html(ph);
    });
}

$(document).ready(function() {
  $('.floating-placeholder input').keyup(function() {
    var input = $(this).val();
    if(input) $(this).parent().addClass('float');
    else $(this).parent().removeClass('float');
  });

  $('#form').submit(function(e) {
    e.preventDefault();
  });

  initTricks();
})