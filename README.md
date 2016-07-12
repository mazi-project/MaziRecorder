# MaziRecorder

## TODO

* [x] Load persisted state
* [x] Create network manager
* [x] Styling
* [x] Reseting Interview
* [x] Color questions depening on if they are answered
* [x] RecorderView : Load tags from model and update attachment in interview model instead of pushing it
* [ ] Upload View
* [x] Fix Label Text
* [x] Sound Visualisation for Audio Recorder
* [ ] Scroll up when the keyboard appears
* [ ] Fix retain cycles



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
