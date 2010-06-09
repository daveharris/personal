javascript:
var showName=prompt('Enter the show name', '');
var tvRageShowName=showName.replace(/\s/g, '_');
var tvRageUrl='http://www.tvrage.com/' + tvRageShowName + '/episode_list';
window.location = tvRageUrl;
