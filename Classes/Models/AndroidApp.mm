//
//  AndroidApp.m
//  AppSendr
//
//  decompressXML is based on work by Robo -
//  http://stackoverflow.com/questions/2097813/how-to-parse-the-androidmanifest-xml-file-inside-an-apk-package
//
//  Created by Nolan Brown on 4/11/12.

#include <Carbon/Carbon.h>
#include <string>
#import "AndroidApp.h"
#import "SSZipArchive.h"
#import "XMLReader.h"
#import "Icon.h"
typedef unsigned long DWORD;
typedef unsigned char BYTE;

struct decompressXML
{
    // decompressXML -- Parse the 'compressed' binary form of Android XML docs 
    // such as for AndroidManifest.xml in .apk files
    enum
    {
        endDocTag = 0x00100101,
        startTag =  0x00100102,
        endTag =    0x00100103
    };

    char * xmlByteStr;

    decompressXML(const BYTE* xml, int cb) {
        // Compressed XML file/bytes starts with 24x bytes of data,
        // 9 32 bit words in little endian order (LSB first):
        //   0th word is 03 00 08 00
        //   3rd word SEEMS TO BE:  Offset at then of StringTable
        //   4th word is: Number of strings in string table
        // WARNING: Sometime I indiscriminently display or refer to word in 
        //   little endian storage format, or in integer format (ie MSB first).
        int numbStrings = LEW(xml, cb, 4*4);
        
        // StringIndexTable starts at offset 24x, an array of 32 bit LE offsets
        // of the length/string data in the StringTable.
        int sitOff = 0x24;  // Offset of start of StringIndexTable
        
        // StringTable, each string is represented with a 16 bit little endian 
        // character count, followed by that number of 16 bit (LE) (Unicode) chars.
        int stOff = sitOff + numbStrings*4;  // StringTable follows StrIndexTable
        
        // XMLTags, The XML tag tree starts after some unknown content after the
        // StringTable.  There is some unknown data after the StringTable, scan
        // forward from this point to the flag for the start of an XML start tag.
        int xmlTagOff = LEW(xml, cb, 3*4);  // Start from the offset in the 3rd word.
        // Scan forward until we find the bytes: 0x02011000(x00100102 in normal int)
        for (int ii=xmlTagOff; ii<cb-4; ii+=4) {
            if (LEW(xml, cb, ii) == startTag) { 
                xmlTagOff = ii;  break;
            }
        } // end of hack, scanning for start of first start tag
        
        // XML tags and attributes:
        // Every XML start and end tag consists of 6 32 bit words:
        //   0th word: 02011000 for startTag and 03011000 for endTag 
        //   1st word: a flag?, like 38000000
        //   2nd word: Line of where this tag appeared in the original source file
        //   3rd word: FFFFFFFF ??
        //   4th word: StringIndex of NameSpace name, or FFFFFFFF for default NS
        //   5th word: StringIndex of Element Name
        //   (Note: 01011000 in 0th word means end of XML document, endDocTag)
        
        // Start tags (not end tags) contain 3 more words:
        //   6th word: 14001400 meaning?? 
        //   7th word: Number of Attributes that follow this tag(follow word 8th)
        //   8th word: 00000000 meaning??
        
        // Attributes consist of 5 words: 
        //   0th word: StringIndex of Attribute Name's Namespace, or FFFFFFFF
        //   1st word: StringIndex of Attribute Name
        //   2nd word: StringIndex of Attribute Value, or FFFFFFF if ResourceId used
        //   3rd word: Flags?
        //   4th word: str ind of attr value again, or ResourceId of value
        
        // TMP, dump string table to tr for debugging
        //tr.addSelect("strings", null);
        //for (int ii=0; ii<numbStrings; ii++) {
        //  // Length of string starts at StringTable plus offset in StrIndTable
        //  String str = compXmlString(xml, sitOff, stOff, ii);
        //  tr.add(String.valueOf(ii), str);
        //}
        //tr.parent();
        
        std::string xmlStr;
        // Step through the XML tree element tags and attributes
        int off = xmlTagOff;
        int indent = 0;
        int startTagLineNo = -2;
        while (off < cb) {
            int tag0 = LEW(xml, cb, off);
            //int tag1 = LEW(xml, off+1*4);
            int lineNo = LEW(xml, cb, off+2*4);
            //int tag3 = LEW(xml, off+3*4);
            //int nameNsSi = LEW(xml, cb, off+4*4);
            int nameSi = LEW(xml, cb, off+5*4);
            
            if (tag0 == startTag) { // XML START TAG
                //int tag6 = LEW(xml, cb, off+6*4);  // Expected to be 14001400
                int numbAttrs = LEW(xml, cb, off+7*4);  // Number of Attributes to follow
                //int tag8 = LEW(xml, off+8*4);  // Expected to be 00000000
                off += 9*4;  // Skip over 6+3 words of startTag data
                std::string name = compXmlString(xml, cb, sitOff, stOff, nameSi);
                //tr.addSelect(name, null);
                startTagLineNo = lineNo;
                
                // Look for the Attributes
                std::string sb;
                for (int ii=0; ii<numbAttrs; ii++) {
                    //int attrNameNsSi = LEW(xml, cb, off);  // AttrName Namespace Str Ind, or FFFFFFFF
                    int attrNameSi = LEW(xml, cb, off+1*4);  // AttrName String Index
                    int attrValueSi = LEW(xml, cb, off+2*4); // AttrValue Str Ind, or FFFFFFFF
                    //int attrFlags = LEW(xml, cb, off+3*4);
                    int attrResId = LEW(xml, cb, off+4*4);  // AttrValue ResourceId or dup AttrValue StrInd
                    off += 5*4;  // Skip over the 5 words of an attribute
                    
                    std::string attrName = compXmlString(xml, cb, sitOff, stOff, attrNameSi);
                    std::string attrValue = attrValueSi!=-1 ? compXmlString(xml, cb, sitOff, stOff, attrValueSi) : "resourceID 0x"+toHexString(attrResId);
                    
                    sb.append(" ");
                    sb.append(attrName);
                    sb.append("=\"");
                    sb.append(attrValue);
                    sb.append("\"");
                    
                    //tr.add(attrName, attrValue);
                }
                xmlStr.append("<"+name+sb+">");
                prtIndent(indent, "<"+name+sb+">");
                indent++;
                
            } else if (tag0 == endTag) { // XML END TAG
                indent--;
                off += 6*4;  // Skip over 6 words of endTag data
                std::string name = compXmlString(xml, cb, sitOff, stOff, nameSi);
                xmlStr.append("</"+name+">");

                prtIndent(indent, "</"+name+">");//  (line "+toIntString(startTagLineNo)+"-"+toIntString(lineNo)+")");
                //tr.parent();  // Step back up the NobTree
                
            } else if (tag0 == endDocTag) {  // END OF XML DOC TAG
                break;
                
            } else {
                prt("  Unrecognized tag code '"+toHexString(tag0)
                    +"' at offset "+toIntString(off));
                break;
            }
        } // end of while loop scanning tags and attributes of XML tree
        prt("    end at offset "+off);
        
        //prt(xmlStr);
            
        xmlByteStr = new char [xmlStr.size()];
        strcpy(xmlByteStr, xmlStr.c_str());
        
        //return xmlStr;
    } // end of decompressXML


    std::string compXmlString(const BYTE* xml, int cb, int sitOff, int stOff, int strInd) {
        if (strInd < 0) return std::string("");
        int strOff = stOff + LEW(xml, cb, sitOff+strInd*4);
        return compXmlStringAt(xml, cb, strOff);
    }

    void prt(std::string str)
    {
        //printf("%s", str.c_str());
    }

    void prtIndent(int indent, std::string str) {
        char spaces[46];
        memset(spaces, ' ', sizeof(spaces));
        spaces[MIN(indent*2,  sizeof(spaces) - 1)] = 0;
        prt(spaces);
        prt(str);
        prt("\n");
    }


    // compXmlStringAt -- Return the string stored in StringTable format at
    // offset strOff.  This offset points to the 16 bit string length, which 
    // is followed by that number of 16 bit (Unicode) chars.
    std::string compXmlStringAt(const Byte* arr, int cb, int strOff) {
        if (cb < strOff + 2) return std::string("");
        int strLen = (arr[strOff+1]<<8&0xff00) | (arr[strOff]&0xff);
        char* chars = new char[strLen + 1];
        chars[strLen] = 0;
        for (int ii=0; ii<strLen; ii++) {
            if (cb < strOff + 2 + ii * 2)
            {
                chars[ii] = 0;
                break;
            }
            chars[ii] = arr[strOff+2+ii*2];
        }
        std::string str(chars);
        free(chars);
        return str;
    } // end of compXmlStringAt


    // LEW -- Return value of a Little Endian 32 bit word from the byte array
    //   at offset off.
    int LEW(const BYTE* arr, int cb, int off) {
        return (cb > off + 3) ? ( (arr[off+3]<<24&0xff000000) | (arr[off+2]<<16&0xff0000) | (arr[off+1]<<8&0xff00) | (arr[off]&0xFF) ) : 0;
    } // end of LEW

    std::string toHexString(DWORD attrResId)
    {
        char ch[20];
        sprintf(ch, "%lx", attrResId);
        return std::string(ch);
    }
    std::string toIntString(int i)
    {
        char ch[20];
        sprintf(ch, "%d", i);
        return std::string(ch);
    }
};


@implementation AndroidApp
@synthesize manifest = manifest_, apkPath = apkPath_, appPath = appPath_, activities = activities_, permissions = permissions_;

- (id) initWithSourcePath: (NSString *) sourcePath proccessingFinished:(void (^)(ASApp *app,BOOL success)) callback {
    self = [super initWithSourcePath:sourcePath];
    if (self) {
        
        // going to be an APK
        self.apkPath = [self.cachePath stringByAppendingPathComponent:self.sourceFilename];
        NSError *error = nil;
        
        // copy APK to cache directory
        [[NSFileManager defaultManager] copyItemAtPath:self.sourcePath toPath:self.apkPath error:&error];
        
        NSString *appDirectory = [self.cachePath stringByAppendingPathComponent:[self.sourceFilename stringByDeletingPathExtension]];
        
        // open APK
        if([SSZipArchive unzipFileAtPath:self.apkPath toDestination:appDirectory]) {
            self.appPath = appDirectory;
        }
        
        
        NSString *manifestPath = [self.appPath stringByAppendingPathComponent:@"AndroidManifest.xml"];
       // manifestPath
        
        ASLog(@"apkPath %@", self.apkPath);
        ASLog(@"manifestPath %@", manifestPath);

        
        error = nil;
        NSData *data_ = [NSData dataWithContentsOfFile:manifestPath options:NSDataReadingMappedIfSafe error:&error];
        
        int len = (int)[data_ length];
        Byte *byteData = (Byte*)malloc(len);
        memcpy(byteData, [data_ bytes], len);
        
        char * byteStr = decompressXML::decompressXML(byteData, len).xmlByteStr;
        
        NSString *string = [NSString stringWithCString:byteStr encoding:[NSString defaultCStringEncoding]];
        free(byteStr);
        
        error = nil;
        NSDictionary *manifest = [XMLReader dictionaryForXMLString:string error:&error];
        if(manifest) {
            ASLog(@"manifest %@",manifest);
            self.manifest = manifest[@"manifest"];
            
            self.name = [self.sourceFilename stringByDeletingPathExtension];
            self.version = (self.manifest)[@"versionName"];
            self.identifier = (self.manifest)[@"package"];
            
            NSMutableArray *allPermissions = [NSMutableArray array];
            NSArray *permissions = (self.manifest)[@"uses-permissions"];
            for (NSDictionary *permission in permissions) {
                NSString *permissionName = permission[@"name"];
                if(permissionName)
                    [allPermissions addObject:permissionName];
            }
            self.permissions = allPermissions;
            self.activities = (self.manifest)[@"activity"];

        }

    
        self.icon = [[Icon alloc] initWithApp:self imageProcessingFinished:^(Icon *icon){
            self.icon = icon;
            callback(self,YES);
        }];
    }
    return self;
    
    
}

- (void)dealloc
{
    
    manifest_ = nil;
    apkPath_ = nil;
    appPath_ = nil;
    activities_ = nil;
    permissions_ = nil;
}

//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.manifest forKey:@"manifest"];
    [encoder encodeObject:self.apkPath forKey:@"apkPath"];
    [encoder encodeObject:self.appPath forKey:@"appPath"];
    [encoder encodeObject:self.activities forKey:@"activities"];
    [encoder encodeObject:self.permissions forKey:@"permissions"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ((self = [super initWithCoder:decoder])) {
        self.manifest = [decoder decodeObjectForKey:@"manifest"];
        self.apkPath = [decoder decodeObjectForKey:@"apkPath"];
        self.appPath = [decoder decodeObjectForKey:@"appPath"];
        self.activities = [decoder decodeObjectForKey:@"activities"];
        self.permissions = [decoder decodeObjectForKey:@"permissions"];
    }
    return self;
}

@end

