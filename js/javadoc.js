javascript:
var packageName=prompt('Enter the fully qualified package name', '');
var packageNameUrl=packageName.replace(/\./g, '/');
var url='http://download.oracle.com/javase/6/docs/api/' + packageNameUrl + '.html';
window.location = url;
