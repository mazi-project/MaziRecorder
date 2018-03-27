# MaziRecorder

The code is under development and is not ready for distribution.

## TODO

* [x] Load persisted state
* [x] Create network manager
* [x] Styling
* [x] Add manual resetting functionality
* [x] Color questions depending on if they are answered
* [x] Recorder view: load tags from model and update attachment in interview model instead of creating a new one
* [x] Add upload feedback
* [x] Fix label text in recording view
* [x] Sound visualisation for audio recorder
* [x] Scroll up when the keyboard appears
* [x] Fix retain cycles
* [x] Reset interview after submitting
* [x] Fix bug where photo isn't displayed



## API Examples

```
# POST api/interviews/ (returns interview: { _id : xxx, ...})
{
  text: 'Synopsis Lorem ipsum',
  name: 'Peter'
  role: 'Designer'
}

# POST api/file/upload/image/:interviewId (returns interview)
FILES['file'] = file

# POST api/attachments/ (returns attachment: { _id : xxx, ...})
{
	text: 'Question text',
	tags: ['test1' , 'test2'],
	interview: interviewId // obtained after creating the interview
}

# POST api/upload/attachment/:attachmentId (returns attachment)
FILES['file'] = file

```
