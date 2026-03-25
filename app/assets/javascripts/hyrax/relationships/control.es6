/**
 * Copied from hyrax 2.5 to add relationship
 **/


import Registry from './registry'
import Resource from './resource'
/**
 * This depends on the passed in element containing `data-autocomplete="work'"`
 * that is also a select2 element.
*/
export default class RelationshipsControl {

  /**
   * COPIED FROM HYRAX TO ADD RELATIONSHIP FOR RELATED ITEMS
   * Initializes the class in the context of an individual table element
   * @param {HTMLElement} element the table element that this class represents.
   * @param {Array} members the members to display in the table
   * @param {String} paramKey the key for the type of object we're submitting (e.g. 'generic_work')
   * @param {String} property the property to submit
   * @param {String} templateId the template identifier for new rows
   * @param {String} relationship the type of relationship for oer items
   */
  constructor(element, members, paramKey, property, templateId, relationship) {
    this.element = $(element)
    this.members = this.element.data('members')
    this.relationship = relationship
    this.registry = new Registry(this.element.find('tbody'), paramKey, property, templateId, relationship)
    this.input = this.element.find(`[data-autocomplete], .collection-select2`)
    this.warning = this.element.find(".message.has-warning")
    this.addButton = this.element.find("[data-behavior='add-relationship']")
    this.errors = null
  }

  init() {
    this.ensureSelect2();
    this.bindAddButton();
    this.displayMembers();
  }

  /**
   * Ensure Select2 is initialized on collection dropdowns before reading selection
   * via select2('data'). Without this, the first "Add" can receive a jQuery object
   * (so data.text is jQuery.fn.text) and the row shows minified JS instead of the title.
   * Matches upstream Hyrax RelationshipsControl#ensureSelect2.
   */
  ensureSelect2() {
    let collectionSelect = this.input.filter('.collection-select2, select[name="member_of_collection_ids"]')
    // Select2 3.x stores the instance on .data('select2'); 4.x may also use select2-hidden-accessible
    if (collectionSelect.length > 0 && !collectionSelect.data('select2') && !collectionSelect.hasClass('select2-hidden-accessible')) {
      let dropdownParent = collectionSelect.closest('.modal-body')
      let options = {
        placeholder: collectionSelect.data('placeholder') || 'Select',
        allowClear: true
      }
      if (dropdownParent.length > 0) {
        options.dropdownParent = dropdownParent
      }
      collectionSelect.select2(options)
    }
  }

  validate() {
    if (this.input.val() === "") {
      this.errors = ['ID cannot be empty.']
    }
  }

  // added relationship
  displayMembers() {
    this.members.forEach((elem) =>
      this.registry.addResource(new Resource(elem.id, elem.label, elem.relationship))
    )
  }

  isValid() {
    this.validate()
    return this.errors === null
  }

  /**
   * Handle click events by the "Add" button in the table, setting a warning
   * message if the input is empty or calling the server to handle the request
   */
  bindAddButton() {
    this.addButton.on("click", () => this.attemptToAddRow())
  }

  attemptToAddRow() {
      // Display an error when the input field is empty, or if the resource ID is already related,
      // otherwise clone the row and set appropriate styles
      if (this.isValid()) {
        this.addRow()
      } else {
        this.setWarningMessage(this.errors.join(', '))
      }
  }

  addRow() {
    this.hideWarningMessage()
    let data = this.searchData()
    this.registry.addResource(new Resource(data.id, data.text))

    // finally, empty the "add" row input value
    this.clearSearch();
  }

  searchData() {
    return this.input.select2('data')
  }

  clearSearch() {
    this.input.select2("val", '');
  }

  /**
   * Set the warning message related to the appropriate row in the table
   * @param {String} message the warning message text to set
   */
  setWarningMessage(message) {
    this.warning.text(message).hidden= false;
  }

  /**
   * Hide the warning message on the appropriate row
   */
  hideWarningMessage(){
    this.warning.hidden= true;
  }
}
