// OVERRIDE Hyrax v5.2.0 to change the autocomplete message prompt for language code authorities
// Library of Congress language code authorities (loc/languages and loc/iso639-2) require 3 characters to search

// Autocomplete for linked data elements using a select2 autocomplete widget
// After selecting something, the selected item is immutable
export default class LinkedData {
  constructor(element, url) {
    this.url = url
    this.element = element
    this.activate()
  }

  activate() {
    this.element
      .select2(this.options(this.element))
      .on("change", (e) => { this.selected(e) })
  }

  // Called when a choice is made
  selected(e) {
    let result = this.element.select2("data")
    this.element.select2("destroy")
    this.element.val(result.label).attr("readonly", "readonly")
    // Adding d-block class to the remove button to show it after a selection is made.
    let removeButton = this.element.closest('.field-wrapper').find('.input-group-btn.field-controls .remove')
    removeButton.addClass('d-block')
    this.setIdentifier(result.id)
  }

  // Store the uri in the associated hidden id field
  setIdentifier(uri) {
    this.element.closest('.field-wrapper').find('[data-id]').val(uri)
  }

  options(element) {
    // Sets a three character minimum for language code authorities
    const languageAuthority = this.url && (
      this.url.includes('/loc/languages') ||
      this.url.includes('/loc/iso639-2')
    )

    // placeholder: $(this).attr("value") || "Search for a location",
    return {
      minimumInputLength: languageAuthority ? 3 : 2,
      language: languageAuthority ? {
        inputTooShort: function () {
          return 'Please enter a 3 character language code'
        }
      } : undefined,
      id: function (object) {
        return object.id
      },
      text: function (object) {
        return object.label
      },
      initSelection: function (element, callback) {
        var data = {
          id: element.val(),
          label: element[0].dataset.label || element.val()
        }
        callback(data)
      },
      ajax: {
        url: this.url,
        dataType: "json",
        data: function (term, page) {
          return {
            q: term
          }
        },
        results: function (data, page) {
          return { results: data }
        }
      }
    }
  }
}
