// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadResourceTypes() {
  $( '.js-resource_type' ).on('focus', function () {
    $('.saving_text').show();
    $('.saved_text').hide();
    previous_value = this.value;
    }).change(function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this.form);
        $(form).trigger('submit.rails');
      }
    });

  $( '.js-resource_type' ).blur(function (event) {
    $('.saved_text').show();
    $('.saving_text').hide();
  });
};


