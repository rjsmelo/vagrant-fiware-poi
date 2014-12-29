# Vagrant box with FIWARE POI Provider

This is a Vagrant Box to quickly test the FIWARE POI Provider Server.

The setup is based on the [Installation and Administration Guide](http://forge.fi-ware.org/plugins/mediawiki/wiki/fiware/index.php/POI_Data_Provider_-_Installation_and_Administration_Guide) available at Fiware Forge.

### Usage

You will need a working setup with Git, VirtualBox and Vagrant.

```
git clone --recursive https://github.com/rjsmelo/vagrant-fiware-poi.git
cd vagrant-fiware-poi
vagrant up
```

**Testing**

After the provisioning finish and the VM is fully running, the local port `8080` will be forwarded to the VM port `80` and you can test if everything is ok by going to the following URL in your browser:
 
[http://localhost:8080/radial_search?lat=1&lon=1&category=test_poi](http://localhost:8080/radial_search?lat=1&lon=1&category=test_poi)

it should return a JSON structure like this:

```
{  
  "pois":{  
    "ae01d34a-d0c1-4134-9107-71814b4805af":{  
      "fw_core":{  
        "location":{  
          "wgs84":{  
            "latitude":1,
            "longitude":1
          }
        },
        "category":"test_poi",
        "name":{  
          "":"Test POI 1"
        }
      }
    }
  }
}
```

### Diferences from the Installation Guide

* Ubuntu Version: the guide suggests Ubuntu 12.04, but we use version 14.04
* GitHub Repository: Instead of cloning `https://github.com/Chiru/WeX` we use `https://github.com/Chiru/FIWARE-POIDataProvider` since the `README.md` at the first says this is the new repo.
* We checkout a specific commit (`6796d31`) since it's the last before switching to the 3.5 schema, after that commit the install_scripts don't match the schema, so it won't work out of the box.
* An Apache Redirect rule has been added to map the requiests without `.php` to the apropriate PHP file, example: `/get_components -> get_components.php` to comply with the POI standard endpoint name.

### Contributing

If you find any issue, please go to GitHub, fork the original project and make your pull requests at will.

Project Repository: [https://github.com/rjsmelo/vagrant-fiware-poi](https://github.com/rjsmelo/vagrant-fiware-poi)

Released under the terms of MIT License.
