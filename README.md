# MaziRecorder

## TODO

* [ ] Load persisted state
* [ ] Create Network manager
* [ ] Styling
* [ ] Reseting Interview
* [ ] Color questions depening on if they are answered
* [ ] Upload View
* [ ] Fix Label Text
* [x] Sound Visualisation for Audio Recorder



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