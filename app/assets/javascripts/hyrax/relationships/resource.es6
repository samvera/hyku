/*
 * Copied from hyrax 2.5 to add relationship
 * Represents a Child work or related Collection
 */
export default class Resource {
  constructor(id, title, relationship) {
      this.id = id
      this.title = title
      this.relationship = relationship
      this.index = 0
  }
}
