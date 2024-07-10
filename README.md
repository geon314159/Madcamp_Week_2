# GMS(Group Management System)를 소개합니다



여러 카톡방에 흩어져 있는 공지가 찾기 힘드시다구요?

일정을 정해야 하는데 when2meet을 기록하지 않는 팀원이 있어 일정을 정할 수 없다구요?

당신의 현명한 단체생활을 위한 단체 관리 어플이 여기 있습니다!
<br>

## Team


- [조영서](https://www.notion.so/9c9e5bc511ff4fb2bd9f317a13ce13a0?pvs=21) - Frontend
  - [cyshello - Overview](https://github.com/cyshello)

- [강건](https://www.notion.so/a9f5fe76226a458b976db96edcffcf20?pvs=21) - Backend
  - [geon314159 - Overview](https://github.com/geon314159)

<br>

## Tech Stack



- **Frontend**: Flutter
- **Backend**: Flask + MySQL
<br>


## Details


### 1. Login

- 처음 들어가면 상단에 로고가 있는 로그인 화면이 나타납니다.
- 기존 사용자라면 이메일과 비밀번호를 입력하여 들어갈 수 있고, 새로운 사용자는 기본 회원 가입을 사용하거나 카카오 계정을 활용하여 계정을 만들 수 있습니다.

![Login](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/291915d1-57b6-4a09-94c3-ed7992c391f6/Untitled.png)
![Login](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/0dd54a4e-bbe0-45ce-92cd-57975d0a6efb/Untitled.png)
![Login](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/d7913530-96df-4a4a-8e77-399310aae923/Untitled.png)

<br>
<br>

### 2. Main Screen & User Profile

- Main Screen에서는 본인의 간단한 프로필 정보를 위에서 볼 수 있고, 하단의 탭에서는 그룹을 만들거나 참여할 수 있습니다.
- 본인이 추가되어있는 그룹은 이름, 설명, 참여자 수의 정보를 메인 화면에서 확인할 수 있고, 해당 그룹에서 본인의 권한에 따라 리더, 멤버로 표시됩니다.
- 하단의 화면을 끌어올리면 그룹을 만들거나 참여할 수 있는 버튼이 나타납니다. 그룹을 처음 만들면 만든 사람에게 초대 코드가 주어지고, 해당 초대 코드를 다른 사람이 입력하면 그룹에 참여할 수 있습니다.
- 프로필을 누르면 상세 프로필 페이지로 이동하며, 유저의 이메일과 프로필 사진, 시간표 정보를 확인할 수 있으며, 각각 수정 또한 가능합니다.

![Main Screen](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/b2f6998c-bcf4-4c4f-866b-a1c543761a81/Untitled.png)
![Main Screen](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/e1ab5355-7da3-4949-a2e0-4c1c784cb829/Untitled.png)
![Main Screen](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/40bc366b-c984-464c-b7e8-36bde5f41bc2/Untitled.png)

<br>
<br>


### 3. Group Page

#### 1) Main

- 그룹 페이지에서는 해당 그룹의 리더인 경우, 공지글, 미팅, 팀 추가/수정/삭제 등의 기능이 가능합니다.
- 우측 하단의 버튼을 눌러 원하는 동작을 선택할 수 있습니다.
- 게시글에서는 사진을 포함하여 작성할 수 있으며, 원하는 태그를 선택하여 업로드가 가능합니다.
- 미팅을 만들기를 시작하면, 먼저 필요한 시간 정보와 참여할 유저들의 목록을 받습니다. 이후 해당 유저들의 시간표 정보를 수합하여, 전체 인원이 가능한 시간 목록을 확인하여 미팅 시간을 확정할 수 있습니다.
- 미팅이 생성되면, 해당 정보를 기반으로 공지글이 작성됩니다.

![Group Main](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/433a1afa-a81a-4d08-80ef-3f38d00586e3/Untitled.png)
![Group Main](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/224929c7-e768-4deb-a15a-60c7ea6b3573/Untitled.png)
![Group Main](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/1aa447c1-18ce-4125-83f2-7059775b738d/Untitled.png)

<br>
<br>


#### 2) Tag

- 게시글의 경우 태그를 통한 필터링으로, 원하는 태그의 게시글을 확인할 수 있습니다.
- 태그의 수정이 가능하며, 이름과 색상을 선택하여 원하는 태그를 새롭게 커스터마이즈 할 수 있습니다.

![Tag](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/1a8b1d5f-03b3-4400-b71c-4fb4e74ed8cb/Untitled.png)
![Tag](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/5912223e-96e1-4cf1-be06-120549412579/Untitled.png)
![Tag](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/9e650a0e-12da-4697-8de0-85223a598811/Untitled.png)

#### 3) Schedule

- 하단의 스케줄 네비게이션 바로 들어가면 캘린더가 나타납니다.
- 해당 그룹에서 생성된 미팅들을 확인할 수 있으며, 수정도 가능합니다.

![Schedule](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/30bb9ae4-6292-4191-8348-80fff3afd09a/Untitled.png)
![Schedule](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/5e9028e2-fc97-4446-a442-f6093416ef4d/Untitled.png)
![Schedule](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/e7ec96e9-95ed-4d3c-8d84-58027e0a45dc/Untitled.png)

<br>
<br>


### 4. Team Page

- 그룹 페이지에서 하단의 팀 네비게이션 바로 들어가면, 그룹에 소속된 팀 화면이 나타납니다.
- 해당 그룹에서 생성된 팀들을 확인할 수 있으며, 참여중인 팀 멤버 수도 확인할 수 있습니다.
- 해당 팀의 리더 프로필을 확인할 수 있고, 본인이 리더일 경우 리더 표시를 확인할 수 있습니다.
- 팀을 누르면 팀 상세 페이지로 이동하며, 기능은 그룹 페이지와 동일합니다.
- 이때 태그는 팀이 소속된 그룹의 태그를 그대로 사용할 수 있습니다.

![Team Page](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/862f6121-f85e-4bb6-8261-7a295814303a/Untitled.png)
![Team Page](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/1fa0388e-9108-4f3a-8e96-c347e7659729/Untitled.png)
![Team Page](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/2448f184-eab4-48d4-a252-d6af9254a99f/Untitled.png)

<br>
<br>


## DB Design


- 전반적인 디자인은 아래 diagram 참고 부탁드립니다.

![DB Design](https://prod-files-secure.s3.us-west-2.amazonaws.com/f6cb388f-3934-47d6-9928-26d2e10eb0fc/215c3d9b-fc79-42a4-bf3d-96723b7cfd71/DB.png)

[A Free Database Designer for Developers and Analysts](https://dbdiagram.io/d/668d07c79939893dae6ee38a)

<br>
<br>

## APK File
- TBD
