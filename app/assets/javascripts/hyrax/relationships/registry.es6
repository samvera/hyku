/**
 * Copied from hyrax 2.5 to add relationship
 **/

 import RegistryEntry from './registry_entry'
export default class Registry {
  /**
   * COPIED FROM HYRAX TO ADD RELATIONSHIP FOR RELATED ITEMS
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container.
   *                         must be a table with a tbody element.
   * @param {String} object_name the name of the object, for constructing form fields (e.g. 'generic_work')
   * @param {String} templateId the the identifier of the template for the added elements
   * @param {String} relationship the indentifier of which relationship being added
   */
  constructor(element, objectName, propertyName, templateId, relationship) {
    this.objectName = objectName
    this.propertyName = propertyName
    this.relationship = relationship
    this.templateId = templateId
    this.items = []
    this.element = element
    element.closest('form').on('submit', (evt) => {
        this.serializeToForm()
    });
  }

  // Return an index for the hidden field when adding a new row.
  // A large random will probably avoid collisions.
  nextIndex() {
      return Math.floor(Math.random() * 1000000000000000)
  }

  export() {
      return this.items.map(item => item.export())
  }

  // ADDED RELATIONSHIP
  serializeToForm() {
      this.export().forEach((item, index) => {
          let nextIndex = this.nextIndex()
          this.addHiddenField(nextIndex, 'id', item.id)
          this.addHiddenField(nextIndex, '_destroy', item['_destroy'])
          this.addHiddenField(nextIndex, 'relationship', item.relationship)
      })
  }

  addHiddenField(index, key, value) {
    // Check if the value is an object and not null
    if (typeof value === 'object' && value !== null) {
        value = JSON.stringify(value);
    }

    $('<input>').attr({
        type: 'hidden',
        name: `${this.fieldPrefix(index)}[${key}]`,
        value: value
    }).appendTo(this.element);
  }

  // ADDED RELATIONSHIP
  // Adds the resource to the first row of the tbody
  addResource(resource) {
    resource.index = this.nextIndex()
    let entry = new RegistryEntry(resource, this, this.templateId, this.relationship)
    this.items.push(entry)
    this.element.prepend(entry.view)
    this.showSaveNote()
  }

  fieldPrefix(counter) {
    return `${this.objectName}[${this.propertyName}][${counter}]`
  }

  showSaveNote() {
    // TODO: we may want to reveal a note that changes aren't active until the resource is saved
  }
}
