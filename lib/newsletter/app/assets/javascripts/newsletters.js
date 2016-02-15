// written by Tyler back in the day.
// horrifically hard to understand.

// some pointers:
//   there's a secret magical div at the bottom of the edit page, #section_template
//   which
//     a) contains the basic editing form that gets cloned for each new template block
//     b) contains (as part of that) the idx and order numbers that allow each new block to be slotted in 

var tmOptions = {
  mode: 'textareas',
  theme: 'advanced',
  editor_selector: 'rich',
  theme_advanced_toolbar_location: 'top',
  theme_advanced_toolbar_align: 'left',
  theme_advanced_buttons1: 'bold,italics,underline,strikethrough,forecolor,backcolor,|,justifyleft,justifycenter,justifyright,|,cut,copy,paste,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,code',
  theme_advanced_buttons2: '',
  theme_advanced_buttons3: '',
  theme_advanced_statusbar_location : "bottom",
  theme_advanced_resizing: true,
  convert_urls: 0
}

var Newsletter = {
  sections: [],
  load: function() {
	// alert("NEWSLETTER func load") ;
    Newsletter.findSections();
    $('#new_section').click(Newsletter.newSection);
    if($('#sections .section').length > 0)
      $('#sections').sortable({
        axis: 'y', 
        items: '> .section', 
        stop: Newsletter.endSort, 
        start: Newsletter.startSort
      });
  },
  startSort: function() {
	// alert("NEWSLETTER func startSort") ;
    $('textarea.rich').each(function(i,e) {
		// alert("remove");
		// tinyMCE.execCommand('mceRemoveControl', false, e.id);
    });
  },
  endSort: function(e,ui) {
	// alert("NEWSLETTER func endSort") ;
    $('textarea.rich').each(function(i,e) {
		// tinyMCE.init(tmOptions);
      // tinyMCE.execCommand('mceAddControl', false, e.id);
    });
    
    $('#sections div.section').each(function(i,e) {
		// alert("sort " + i + " -- " + e);
      $(e).find('input.order').val(i);
    });
  },
  findSections: function() {
	// alert("NEWSLETTER func findSections") ;
    $('#sections div.section').each(function(i,e) {
      var section = Newsletter.Section.create($(e));
      section.setupEvents();
      Newsletter.sections.push(section);
    });
  },
  newSection: function(e) {
    var section = Newsletter.Section.create();
    section.draw();
    section.pointer = $('#sections div.section:last');
    section.setupEvents();
    Newsletter.sections.push(section);
    // $('#sections div.section').each(function(i,e) {
		// alert("NEWSLETTER func newSection A " + i ) ;
    //  $(e).find('input.order').val(i);
    // });
    return false;
  },
  Section: {
    find: function(div) {
	  // alert("NEWSLETTER func find") ;
      var idx = $('#sections div.section').index(div)
      return Newsletter.sections[idx]
    },
    pointer: null,
    create: function(ptr) {
	  // alert("NEWSLETTER func create") ;
      function Section() {};
      Section.prototype = Newsletter.Section;
      var newSec = new Section();
      newSec.pointer = ptr;
      return newSec;
    },
    typeSetup: function(sel) {
	  // alert("NEWSLETTER func typeSetup") ;
      tinyMCE.init(tmOptions);
      var section = sel.parent();
      return function() {
        section.find('textarea.rich').each(function(idx,e) {
			// tinyMCE.execCommand('mceAddControl', false, e.id);
        });
      };
    },
    changeType: function(e) {
	  // alert("NEWSLETTER func changeType") ;
      var self = e.data.self;
      if(!$(this).val()) return self.pointer.find('div.form').html('');
      var idx = $(this).siblings('.idx');

      self.pointer.find('div.form').load('/admin/newsletters/section', {id: $(this).val(), idx: idx.val()}, self.typeSetup($(this)));
    },
    setupEvents: function() {
	  // alert("NEWSLETTER func setupEvents") ;
      this.pointer.find('select.type').bind('change', {self:this}, this.changeType);
    },
    draw : function() {
	  // alert("NEWSLETTER func draw ") ;
      $('#sections').append($('#section_template').html());
      var idx = $('#section_template .idx');
	  // alert("ID = " + idx.val() );
      idx.val(1 + (idx.val() - 0));
    }
  }
};

$(Newsletter.load);
tinyMCE.init(tmOptions);

