# MaziRecorder

## TODO

* [x] Load persisted state
* [ ] Create network manager
* [x] Styling
* [x] Resetting interview
* [x] Color questions depending on if they are answered
* [ ] Recorder view: load tags from model and update attachment in interview model instead of pushing it
* [ ] Upload view
* [ ] Fix label text
* [x] Sound visualisation for audio recording view



## API Examples

```
# POST api/interviews/ (returns interview: { _id : xxx, ...})
{
  text: 'Lorem ipsum',
  name: 'Test Peter'
}

# POST api/file/upload/image/:interviewId (returns interview)
FILES['file'] = file

# POST api/attachments/ (returns attachment: { _id : xxx, ...})
{
	text: 'question text',
	tags: ['test1' , 'test2'],
	interview: interviewId
}

# POST api/upload/attachment/:attachmentId (returns attachment)
FILES['file'] = file


```
